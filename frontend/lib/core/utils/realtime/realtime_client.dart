import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:stomp_dart_client/stomp_dart_client.dart';

import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/network/app_api.dart';
import 'package:skill_battles/core/utils/realtime/realtime_envelope.dart';
import 'package:skill_battles/core/utils/session/auth_session.dart';
import 'package:skill_battles/core/utils/session/session_tokens.dart';

/// The personal event stream. Actions always go through REST; the socket
/// only delivers notifications.
abstract interface class RealtimeClient {
  Stream<RealtimeEnvelope> get events;

  Stream<RealtimeStatus> get statusChanges;

  RealtimeStatus get status;

  /// Follows the session: connects when signed in, reconnects with every
  /// new access token, disconnects on sign-out.
  void start();

  Future<void> dispose();
}

/// STOMP 1.2 over a native WebSocket (not SockJS). The access JWT goes only
/// in the CONNECT `Authorization` header — never in the URL or a cookie. One
/// subscription, no SEND frames.
final class StompRealtimeClient implements RealtimeClient {
  StompRealtimeClient({required this._session, String? url})
    : _url = url ?? AppApi.eventsUrl;

  final AuthSession _session;
  final String _url;

  final StreamController<RealtimeEnvelope> _events =
      StreamController<RealtimeEnvelope>.broadcast();
  final StreamController<RealtimeStatus> _statuses =
      StreamController<RealtimeStatus>.broadcast();

  StreamSubscription<SessionTokens?>? _sessionSubscription;
  StompClient? _client;
  String? _connectedToken;
  RealtimeStatus _status = RealtimeStatus.disconnected;

  static const Duration _heartbeat = Duration(seconds: 5);
  static const Duration _reconnectDelay = Duration(seconds: 3);

  @override
  Stream<RealtimeEnvelope> get events => _events.stream;

  @override
  Stream<RealtimeStatus> get statusChanges => _statuses.stream;

  @override
  RealtimeStatus get status => _status;

  @override
  void start() {
    _sessionSubscription ??= _session.changes.listen(_onSession);
    final String? token = _session.accessToken;
    if (token != null) _connect(token);
  }

  void _onSession(SessionTokens? tokens) {
    if (tokens == null) {
      _disconnect();
      return;
    }
    if (tokens.accessToken != _connectedToken) _connect(tokens.accessToken);
  }

  void _connect(String token) {
    _client?.deactivate();
    _connectedToken = token;
    _setStatus(RealtimeStatus.connecting);
    final StompClient client = StompClient(
      config: StompConfig(
        url: _url,
        reconnectDelay: _reconnectDelay,
        heartbeatIncoming: _heartbeat,
        heartbeatOutgoing: _heartbeat,
        stompConnectHeaders: <String, String>{
          AppApi.authorizationHeader: '${AppApi.bearerPrefix} $token',
        },
        beforeConnect: () async => _setStatus(RealtimeStatus.connecting),
        onConnect: _onConnect,
        onStompError: _onStompError,
        onWebSocketDone: () => _setStatus(RealtimeStatus.disconnected),
        onWebSocketError: (Object? error) {
          developer.log(
            'WebSocket error',
            name: 'realtime',
            error: error.runtimeType,
          );
          _setStatus(RealtimeStatus.disconnected);
        },
        onDisconnect: (StompFrame _) => _setStatus(RealtimeStatus.disconnected),
      ),
    );
    _client = client;
    client.activate();
  }

  void _onConnect(StompFrame frame) {
    _client?.subscribe(
      destination: AppApi.eventsDestination,
      headers: <String, String>{'id': AppApi.eventsSubscriptionId},
      callback: (StompFrame message) {
        final RealtimeEnvelope? envelope = RealtimeEnvelope.tryParse(
          message.body,
        );
        if (envelope != null) _events.add(envelope);
      },
    );
    // Listeners re-read their resources after every (re)connect:
    // CONNECT → SUBSCRIBE → GET.
    _setStatus(RealtimeStatus.connected);
  }

  void _onStompError(StompFrame frame) {
    _setStatus(RealtimeStatus.disconnected);
    final String? code = _errorCode(frame.body);
    if (code == ApiErrorCodes.unauthorized) {
      // A new pair arrives through `changes` and reconnects.
      unawaited(_session.refresh());
    }
  }

  static String? _errorCode(String? body) {
    if (body == null) return null;
    try {
      final Object? json = jsonDecode(body);
      if (json is Map<String, dynamic> && json['code'] is String) {
        return json['code'] as String;
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  void _disconnect() {
    _client?.deactivate();
    _client = null;
    _connectedToken = null;
    _setStatus(RealtimeStatus.disconnected);
  }

  void _setStatus(RealtimeStatus status) {
    if (_status == status) return;
    _status = status;
    _statuses.add(status);
  }

  @override
  Future<void> dispose() async {
    await _sessionSubscription?.cancel();
    _disconnect();
    await _events.close();
    await _statuses.close();
  }
}
