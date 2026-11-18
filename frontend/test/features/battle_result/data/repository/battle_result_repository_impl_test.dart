import 'dart:async';

import 'package:test/test.dart';

import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/core/utils/realtime/realtime_client.dart';
import 'package:skill_battles/core/utils/realtime/realtime_envelope.dart';
import 'package:skill_battles/core/utils/session/auth_session.dart';
import 'package:skill_battles/core/utils/storage/token_storage.dart';
import 'package:skill_battles/features/battle_result/data/repository/battle_result_repository_impl.dart';
import 'package:skill_battles/features/battle_result/data/sources/remote/battle_result_remote.dart';
import 'package:skill_battles/features/battle_result/domain/entity/rematch_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/rematch_status.dart';

final class _FakeRealtimeClient implements RealtimeClient {
  final StreamController<RealtimeEnvelope> controller =
      StreamController<RealtimeEnvelope>.broadcast();

  @override
  Stream<RealtimeEnvelope> get events => controller.stream;

  @override
  Stream<RealtimeStatus> get statusChanges =>
      const Stream<RealtimeStatus>.empty();

  @override
  RealtimeStatus get status => RealtimeStatus.connected;

  @override
  void start() {}

  @override
  Future<void> dispose() => controller.close();
}

final class _FakeRemote implements BattleResultRemote {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

RealtimeEnvelope _envelope(
  RealtimeEventType type,
  String resourceId,
  Map<String, dynamic> data, {
  int version = 1,
}) => RealtimeEnvelope(
  eventId: 'e-$resourceId-$version',
  type: type,
  resourceId: resourceId,
  version: version,
  occurredAt: DateTime.utc(2026, 11, 15),
  data: data,
);

Map<String, dynamic> _rematchJson(
  String sourceId, {
  String status = 'WAITING',
}) => <String, dynamic>{
  'sourceBattleId': sourceId,
  'status': status,
  'requestedBy': <String>['u2'],
  'expiresAt': '2026-11-15T12:01:00Z',
  'battleId': null,
  'version': 1,
};

void main() {
  group('BattleResultRepositoryImpl.watchRematches', () {
    late _FakeRealtimeClient realtime;
    late BattleResultRepositoryImpl repository;
    late List<RematchEntity> received;
    late StreamSubscription<RematchEntity> subscription;

    setUp(() {
      realtime = _FakeRealtimeClient();
      repository = BattleResultRepositoryImpl(
        remote: _FakeRemote(),
        realtime: realtime,
        session: AuthSession(
          storage: MemoryTokenStorage(),
          refresher: (_) async => throw UnimplementedError(),
        ),
      );
      received = <RematchEntity>[];
      subscription = repository.watchRematches().listen(received.add);
    });

    tearDown(() async {
      await subscription.cancel();
      await realtime.dispose();
    });

    test('emits every REMATCH_CHANGED whatever the source battle', () async {
      realtime.controller
        ..add(
          _envelope(RealtimeEventType.rematchChanged, 'b1', _rematchJson('b1')),
        )
        ..add(
          _envelope(
            RealtimeEventType.rematchChanged,
            'b2',
            _rematchJson('b2', status: 'CANCELLED'),
          ),
        );
      await Future<void>.delayed(Duration.zero);

      expect(received.map((RematchEntity r) => r.sourceBattleId), <String>[
        'b1',
        'b2',
      ]);
      expect(received.first.status, RematchStatus.waiting);
      expect(received.last.status, RematchStatus.cancelled);
      expect(received.first.requestedBy, <String>['u2']);
    });

    test('ignores other event types', () async {
      realtime.controller
        ..add(
          _envelope(RealtimeEventType.battleChanged, 'b1', _rematchJson('b1')),
        )
        ..add(
          _envelope(
            RealtimeEventType.accountChanged,
            'u1',
            <String, dynamic>{},
          ),
        );
      await Future<void>.delayed(Duration.zero);

      expect(received, isEmpty);
    });

    test('skips a malformed payload and keeps listening', () async {
      realtime.controller
        ..add(
          _envelope(RealtimeEventType.rematchChanged, 'b1', <String, dynamic>{
            'sourceBattleId': 'b1',
          }),
        )
        ..add(
          _envelope(RealtimeEventType.rematchChanged, 'b2', _rematchJson('b2')),
        );
      await Future<void>.delayed(Duration.zero);

      expect(received.map((RematchEntity r) => r.sourceBattleId), <String>[
        'b2',
      ]);
    });
  });
}
