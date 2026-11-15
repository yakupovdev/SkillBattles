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
  StompRealtimeClient({
    required this._session,
    String? url,
    StompClient Function(StompConfig config)? createClient,
  }) : _url = url ?? AppApi.eventsUrl,
       _createClient = createClient ?? _newClient;

  final AuthSession _session;
  final String _url;
  final StompClient Function(StompConfig config) _createClient;

  final StreamController<RealtimeEnvelope> _events =
      StreamController<RealtimeEnvelope>.broadcast();
  final StreamController<RealtimeStatus> _statuses =
      StreamController<RealtimeStatus>.broadcast();

  StreamSubscription<SessionTokens?>? _sessionSubscription;
  StompClient? _client;
  String? _connectedToken;
  RealtimeStatus _status = RealtimeStatus.disconnected;
  int _clientGeneration = 0;
  int _connectionGeneration = 0;
  bool _isDisposed = false;

  static const Duration _heartbeat = Duration(seconds: 5);
  static const Duration _reconnectDelay = Duration(seconds: 3);

  static StompClient _newClient(StompConfig config) =>
      StompClient(config: config);

  @override
  Stream<RealtimeEnvelope> get events => _events.stream;

  @override
  Stream<RealtimeStatus> get statusChanges => _statuses.stream;

  @override
  RealtimeStatus get status => _status;

  @override
  void start() {
    if (_isDisposed) return;
    _sessionSubscription ??= _session.changes.listen(_onSession);
    final String? token = _session.accessToken;
    if (token != null) _connect(token);
  }

  void _onSession(SessionTokens? tokens) {
    if (_isDisposed) return;
    if (tokens == null) {
      _disconnect();
      return;
    }
    if (tokens.accessToken != _connectedToken) _connect(tokens.accessToken);
  }

  void _connect(String token) {
    // Invalidate first: deactivation may synchronously call old callbacks.
    final int generation = ++_clientGeneration;
    _connectionGeneration++;
    _client?.deactivate();
    _connectedToken = token;
    _setStatus(RealtimeStatus.connecting);
    late final StompClient client;
    bool isCurrent() => _isCurrentClient(client, generation);
    void disconnected() {
      if (!isCurrent()) return;
      _connectionGeneration++;
      _setStatus(RealtimeStatus.disconnected);
    }

    client = _createClient(
      StompConfig(
        url: _url,
        reconnectDelay: _reconnectDelay,
        heartbeatIncoming: _heartbeat,
        heartbeatOutgoing: _heartbeat,
        stompConnectHeaders: <String, String>{
          AppApi.authorizationHeader: '${AppApi.bearerPrefix} $token',
        },
        beforeConnect: () async {
          if (!isCurrent()) return;
          _connectionGeneration++;
          _setStatus(RealtimeStatus.connecting);
        },
        onConnect: (StompFrame _) {
          if (isCurrent()) _onConnect(client, generation);
        },
        onStompError: (StompFrame frame) {
          if (!isCurrent()) return;
          _connectionGeneration++;
          _onStompError(frame);
        },
        onWebSocketDone: disconnected,
        onWebSocketError: (Object? error) {
          if (!isCurrent()) return;
          developer.log(
            'WebSocket error',
            name: 'realtime',
            error: error.runtimeType,
          );
          disconnected();
        },
        onDisconnect: (StompFrame _) => disconnected(),
      ),
    );
    _client = client;
    client.activate();
  }

  bool _isCurrentClient(StompClient client, int generation) =>
      !_isDisposed &&
      generation == _clientGeneration &&
      identical(client, _client) &&
      _connectedToken == _session.accessToken;

  void _onConnect(StompClient client, int clientGeneration) {
    // A StompClient also reconnects by itself, reusing its config. Each new
    // subscription therefore needs its own generation as well.
    final int connectionGeneration = ++_connectionGeneration;
    client.subscribe(
      destination: AppApi.eventsDestination,
      headers: <String, String>{'id': AppApi.eventsSubscriptionId},
      callback: (StompFrame message) {
        if (!_isCurrentClient(client, clientGeneration) ||
            connectionGeneration != _connectionGeneration ||
            _status != RealtimeStatus.connected) {
          return;
        }
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
    _clientGeneration++;
    _connectionGeneration++;
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
    if (_isDisposed) return;
    _isDisposed = true;
    _disconnect();
    await _sessionSubscription?.cancel();
    await _events.close();
    await _statuses.close();
  }
}
