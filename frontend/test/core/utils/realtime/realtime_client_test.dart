import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/core/utils/realtime/realtime_client.dart';
import 'package:skill_battles/core/utils/realtime/realtime_envelope.dart';
import 'package:skill_battles/core/utils/session/auth_session.dart';
import 'package:skill_battles/core/utils/session/session_tokens.dart';
import 'package:skill_battles/core/utils/storage/token_storage.dart';

const SessionTokens _initial = SessionTokens(
  accessToken: 'a1',
  refreshToken: 'r1',
  userId: 'u1',
);
const SessionTokens _refreshed = SessionTokens(
  accessToken: 'a2',
  refreshToken: 'r2',
  userId: 'u1',
);

StompFrame _message(String id, {int sequence = 1}) => StompFrame(
  command: 'MESSAGE',
  headers: const <String, String>{},
  body: jsonEncode(<String, Object?>{
    'eventId': id,
    'type': 'BATTLE_STICKER',
    'resourceId': 'b1',
    'version': sequence,
    'occurredAt': '2026-11-15T03:00:00Z',
    'data': <String, Object?>{},
  }),
);

StompFrame _frame(String command, {String? body}) =>
    StompFrame(command: command, headers: const <String, String>{}, body: body);

final class _FakeStompClient extends StompClient {
  _FakeStompClient(StompConfig config) : super(config: config);

  final List<StompFrameCallback> callbacks = <StompFrameCallback>[];
  bool _connected = false;

  @override
  bool get connected => _connected;

  @override
  void activate() {}

  @override
  void deactivate() => _connected = false;

  @override
  StompUnsubscribe subscribe({
    required String destination,
    required StompFrameCallback callback,
    Map<String, String>? headers,
  }) {
    expect(destination, '/user/queue/events');
    callbacks.add(callback);
    return ({Map<String, String>? unsubscribeHeaders}) {};
  }

  Future<void> connect() async {
    await config.beforeConnect();
    _connected = true;
    config.onConnect(_frame('CONNECTED'));
  }

  void disconnect() {
    _connected = false;
    config.onWebSocketDone();
  }
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  late AuthSession session;
  late StompRealtimeClient realtime;
  late List<_FakeStompClient> clients;
  late List<RealtimeEnvelope> events;
  late StreamSubscription<RealtimeEnvelope> subscription;
  late int refreshCalls;

  setUp(() async {
    refreshCalls = 0;
    clients = <_FakeStompClient>[];
    events = <RealtimeEnvelope>[];
    session = AuthSession(
      storage: MemoryTokenStorage(),
      refresher: (String token) async {
        refreshCalls++;
        return _refreshed;
      },
    );
    await session.signIn(_initial);
    realtime = StompRealtimeClient(
      session: session,
      url: 'ws://unused.invalid/events',
      createClient: (StompConfig config) {
        final _FakeStompClient client = _FakeStompClient(config);
        clients.add(client);
        return client;
      },
    );
    subscription = realtime.events.listen(events.add);
    realtime.start();
    await clients.single.connect();
  });

  tearDown(() async {
    await subscription.cancel();
    await realtime.dispose();
    session.dispose();
  });

  test('the active connection publishes its personal events', () async {
    clients.single.callbacks.single(_message('current'));
    await _flush();

    expect(realtime.status, RealtimeStatus.connected);
    expect(events.map((RealtimeEnvelope event) => event.eventId), <String>[
      'current',
    ]);
    expect(
      clients.single.config.stompConnectHeaders?['Authorization'],
      'Bearer a1',
    );
  });

  test('token rotation ignores all callbacks of the replaced client', () async {
    final _FakeStompClient old = clients.single;
    final StompFrameCallback oldMessage = old.callbacks.single;
    await session.signIn(_refreshed);
    await _flush();
    final _FakeStompClient current = clients.last;
    await current.connect();

    await old.config.beforeConnect();
    old.config.onConnect(_frame('CONNECTED'));
    old.config.onWebSocketDone();
    old.config.onWebSocketError(StateError('old socket'));
    old.config.onDisconnect(_frame('DISCONNECT'));
    old.config.onStompError(_frame('ERROR', body: '{"code":"UNAUTHORIZED"}'));
    oldMessage(_message('old', sequence: 40));
    current.callbacks.single(_message('new'));
    await _flush();

    expect(clients, hasLength(2));
    expect(current.callbacks, hasLength(1));
    expect(old.callbacks, hasLength(1));
    expect(refreshCalls, 0);
    expect(realtime.status, RealtimeStatus.connected);
    expect(events.map((RealtimeEnvelope event) => event.eventId), <String>[
      'new',
    ]);
  });

  test('autoreconnect on the same client drops the old subscription', () async {
    final _FakeStompClient client = clients.single;
    final StompFrameCallback oldMessage = client.callbacks.single;
    client.disconnect();
    oldMessage(_message('disconnected', sequence: 40));
    await client.config.beforeConnect();
    oldMessage(_message('connecting', sequence: 40));
    await client.connect();
    oldMessage(_message('old', sequence: 40));
    client.callbacks.last(_message('fresh', sequence: 1));
    await _flush();

    expect(clients, hasLength(1));
    expect(events.map((RealtimeEnvelope event) => event.eventId), <String>[
      'fresh',
    ]);
    expect(events.single.version, 1);
  });

  test(
    'sign out rejects callbacks before the session event is processed',
    () async {
      final _FakeStompClient old = clients.single;
      final Future<void> signingOut = session.signOut();
      old.callbacks.single(_message('signed-out'));
      await signingOut;
      await _flush();

      old.config.onConnect(_frame('CONNECTED'));
      old.callbacks.single(_message('late'));
      await _flush();
      expect(events, isEmpty);
      expect(realtime.status, RealtimeStatus.disconnected);
    },
  );

  test('dispose ignores late callbacks and a repeated start', () async {
    final _FakeStompClient old = clients.single;
    await realtime.dispose();

    await old.config.beforeConnect();
    old.config.onConnect(_frame('CONNECTED'));
    old.config.onWebSocketDone();
    old.config.onStompError(_frame('ERROR', body: '{"code":"UNAUTHORIZED"}'));
    old.callbacks.single(_message('disposed'));
    realtime.start();
    await _flush();

    expect(events, isEmpty);
    expect(clients, hasLength(1));
    expect(refreshCalls, 0);
  });

  test(
    'an unauthorized error on the active connection still refreshes',
    () async {
      clients.single.config.onStompError(
        _frame('ERROR', body: '{"code":"UNAUTHORIZED"}'),
      );
      await _flush();

      expect(refreshCalls, 1);
      expect(clients, hasLength(2));
      await clients.last.connect();
      clients.last.callbacks.single(_message('refreshed'));
      await _flush();
      expect(events.single.eventId, 'refreshed');
    },
  );
}
