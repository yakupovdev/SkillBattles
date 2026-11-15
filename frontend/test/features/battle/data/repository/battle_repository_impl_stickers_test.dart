import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/core/utils/realtime/realtime_client.dart';
import 'package:skill_battles/core/utils/realtime/realtime_envelope.dart';
import 'package:skill_battles/core/utils/session/auth_session.dart';
import 'package:skill_battles/core/utils/storage/token_storage.dart';
import 'package:skill_battles/core/utils/time/clock.dart';
import 'package:skill_battles/features/battle/data/models/answer_receipt_model.dart';
import 'package:skill_battles/features/battle/data/models/answer_request_model.dart';
import 'package:skill_battles/features/battle/data/models/battle_snapshot_model.dart';
import 'package:skill_battles/features/battle/data/models/sticker_receipt_model.dart';
import 'package:skill_battles/features/battle/data/models/sticker_request_model.dart';
import 'package:skill_battles/features/battle/data/repository/battle_repository_impl.dart';
import 'package:skill_battles/features/battle/data/sources/remote/battle_remote.dart';
import 'package:skill_battles/features/battle/domain/entity/incoming_sticker_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/send_sticker_params_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_receipt_entity.dart';

const String _battle = '11111111-1111-4111-8111-111111111111';
const String _submission = '22222222-2222-4222-8222-222222222222';
const String _sender = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

final class _FakeRemote implements BattleRemote {
  final List<(String, Map<String, dynamic>)> stickerCalls =
      <(String, Map<String, dynamic>)>[];
  Object? throws;

  @override
  Future<StickerReceiptModel> sendSticker(
    String id,
    StickerRequestModel request,
  ) async {
    stickerCalls.add((id, request.toJson()));
    final Object? error = throws;
    if (error != null) throw error;
    return StickerReceiptModel.fromJson(<String, dynamic>{
      'battleId': id,
      'submissionId': request.submissionId,
      'senderUserId': _sender,
      'stickerId': request.stickerId,
      'sentAt': '2026-11-15T03:00:00Z',
      'nextAllowedAt': '2026-11-15T03:00:04Z',
    });
  }

  @override
  Future<BattleSnapshotModel> getBattle(String id) =>
      throw UnimplementedError();

  @override
  Future<BattleSnapshotModel> setReady(String id) => throw UnimplementedError();

  @override
  Future<AnswerReceiptModel> submitAnswer(
    String id,
    AnswerRequestModel request,
  ) => throw UnimplementedError();

  @override
  Future<BattleSnapshotModel> surrender(String id) =>
      throw UnimplementedError();
}

final class _FakeRealtime implements RealtimeClient {
  final StreamController<RealtimeEnvelope> controller =
      StreamController<RealtimeEnvelope>.broadcast();

  @override
  Stream<RealtimeEnvelope> get events => controller.stream;

  @override
  RealtimeStatus get status => RealtimeStatus.connected;

  @override
  Stream<RealtimeStatus> get statusChanges =>
      const Stream<RealtimeStatus>.empty();

  @override
  void start() {}

  @override
  Future<void> dispose() => controller.close();
}

/// The sticker paths never touch the session.
final class _UnusedStorage implements TokenStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

RealtimeEnvelope _envelope({
  String eventId = 'e1',
  RealtimeEventType type = RealtimeEventType.battleSticker,
  String resourceId = _battle,
  int version = 3,
  Map<String, dynamic>? data,
}) => RealtimeEnvelope(
  eventId: eventId,
  type: type,
  resourceId: resourceId,
  version: version,
  occurredAt: DateTime.utc(2026, 11, 15, 3),
  data:
      data ??
      <String, dynamic>{
        'battleId': resourceId,
        'submissionId': _submission,
        'senderUserId': _sender,
        'stickerId': 'gg',
        'sentAt': '2026-11-15T03:00:00Z',
      },
);

void main() {
  late _FakeRemote remote;
  late _FakeRealtime realtime;
  late BattleRepositoryImpl repository;

  setUp(() {
    remote = _FakeRemote();
    realtime = _FakeRealtime();
    repository = BattleRepositoryImpl(
      remote: remote,
      realtime: realtime,
      session: AuthSession(
        storage: _UnusedStorage(),
        refresher: (String _) => throw UnimplementedError(),
      ),
      clock: const SystemClock(),
    );
  });

  tearDown(() => realtime.dispose());

  group('sendSticker', () {
    const SendStickerParamsEntity params = SendStickerParamsEntity(
      battleId: _battle,
      stickerId: StickerId.tooSlow,
      submissionId: _submission,
    );

    test('posts only the wire id and the submission id, and maps the '
        'receipt', () async {
      final Either<Failure, StickerReceiptEntity> result = await repository
          .sendSticker(params);

      expect(remote.stickerCalls.single.$1, _battle);
      expect(remote.stickerCalls.single.$2, <String, dynamic>{
        'stickerId': 'too_slow',
        'submissionId': _submission,
      });
      expect(
        result.toNullable(),
        StickerReceiptEntity(
          battleId: _battle,
          submissionId: _submission,
          senderUserId: _sender,
          stickerId: StickerId.tooSlow,
          sentAt: DateTime.utc(2026, 11, 15, 3),
          nextAllowedAt: DateTime.utc(2026, 11, 15, 3, 0, 4),
        ),
      );
    });

    test(
      'keeps the ApiFailure an interceptor stored in the DioException',
      () async {
        final ApiFailure cooldown = ApiFailure(
          statusCode: 429,
          errorCode: ApiErrorCodes.stickerCooldown,
          message: 'Wait before sending another sticker.',
          resetsAt: DateTime.utc(2026, 11, 15, 3, 0, 4),
          retryAfter: const Duration(seconds: 3),
        );
        remote.throws = DioException(
          requestOptions: RequestOptions(path: '/battles/$_battle/stickers'),
          error: cooldown,
        );

        final Either<Failure, StickerReceiptEntity> result = await repository
            .sendSticker(params);

        expect(result.getLeft(), cooldown);
      },
    );

    test('a connection error becomes a ConnectionFailure', () async {
      remote.throws = DioException(
        requestOptions: RequestOptions(path: '/battles/$_battle/stickers'),
        type: DioExceptionType.connectionError,
      );

      final Either<Failure, StickerReceiptEntity> result = await repository
          .sendSticker(params);

      expect(result.getLeft(), isA<ConnectionFailure>());
    });

    test('an Error is a defect and propagates', () async {
      remote.throws = StateError('bug');

      expect(() => repository.sendSticker(params), throwsStateError);
    });
  });

  group('watchStickers', () {
    Future<List<IncomingStickerEntity>> collect(
      List<RealtimeEnvelope> envelopes,
    ) async {
      final List<IncomingStickerEntity> received = <IncomingStickerEntity>[];
      final List<Object> errors = <Object>[];
      final StreamSubscription<IncomingStickerEntity> subscription = repository
          .watchStickers(_battle)
          .listen(received.add, onError: errors.add);
      envelopes.forEach(realtime.controller.add);
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();
      expect(errors, isEmpty);
      return received;
    }

    test(
      'maps the event id and the sticker sequence from the envelope',
      () async {
        final List<IncomingStickerEntity> received = await collect(
          <RealtimeEnvelope>[_envelope(eventId: 'e7', version: 12)],
        );

        expect(
          received.single,
          IncomingStickerEntity(
            eventId: 'e7',
            sequence: 12,
            battleId: _battle,
            submissionId: _submission,
            senderUserId: _sender,
            stickerId: StickerId.gg,
            sentAt: DateTime.utc(2026, 11, 15, 3),
          ),
        );
      },
    );

    test('ignores other event types and other battles', () async {
      final List<IncomingStickerEntity> received = await collect(
        <RealtimeEnvelope>[
          _envelope(type: RealtimeEventType.battleChanged),
          _envelope(resourceId: 'another-battle'),
        ],
      );

      expect(received, isEmpty);
    });

    test('drops an event whose payload names another battle', () async {
      final List<IncomingStickerEntity> received = await collect(
        <RealtimeEnvelope>[
          _envelope(
            data: <String, dynamic>{
              'battleId': 'another-battle',
              'submissionId': _submission,
              'senderUserId': _sender,
              'stickerId': 'gg',
              'sentAt': '2026-11-15T03:00:00Z',
            },
          ),
        ],
      );

      expect(received, isEmpty);
    });

    test(
      'skips a malformed payload without an error and keeps going',
      () async {
        final List<IncomingStickerEntity> received = await collect(
          <RealtimeEnvelope>[
            _envelope(
              eventId: 'bad',
              data: <String, dynamic>{'battleId': _battle},
            ),
            _envelope(eventId: 'good'),
          ],
        );

        expect(received.map((IncomingStickerEntity s) => s.eventId), <String>[
          'good',
        ]);
      },
    );

    test('a sticker id from a newer backend arrives as unknown', () async {
      final List<IncomingStickerEntity> received = await collect(
        <RealtimeEnvelope>[
          _envelope(
            data: <String, dynamic>{
              'battleId': _battle,
              'submissionId': _submission,
              'senderUserId': _sender,
              'stickerId': 'future_sticker_id',
              'sentAt': '2026-11-15T03:00:00Z',
            },
          ),
        ],
      );

      expect(received.single.stickerId, StickerId.unknown);
    });
  });
}
