import 'package:test/test.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/core/utils/realtime/realtime_envelope.dart';
import 'package:skill_battles/features/battle/data/models/battle_sticker_model.dart';
import 'package:skill_battles/features/battle/data/models/sticker_receipt_model.dart';
import 'package:skill_battles/features/battle/data/models/sticker_request_model.dart';
import 'package:skill_battles/features/battle/domain/entity/answer_receipt_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_snapshot_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/incoming_sticker_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/send_sticker_params_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_receipt_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/submit_answer_params_entity.dart';
import 'package:skill_battles/features/battle/domain/repository/battle_repository.dart';
import 'package:skill_battles/features/battle/domain/usecases/send_sticker_usecase.dart';

final class _Repository implements BattleRepository {
  final List<SendStickerParamsEntity> sends = <SendStickerParamsEntity>[];

  @override
  Future<Either<Failure, StickerReceiptEntity>> sendSticker(
    SendStickerParamsEntity params,
  ) async {
    sends.add(params);
    return const Left(TimeoutFailure());
  }

  @override
  Stream<IncomingStickerEntity> watchStickers(String battleId) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, BattleSnapshotEntity>> getBattle(String battleId) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, BattleSnapshotEntity>> setReady(String battleId) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, AnswerReceiptEntity>> submitAnswer(
    SubmitAnswerParamsEntity params,
  ) => throw UnimplementedError();

  @override
  Future<Either<Failure, BattleSnapshotEntity>> surrender(String battleId) =>
      throw UnimplementedError();

  @override
  Stream<BattleSnapshotEntity> watchBattle(String battleId) =>
      throw UnimplementedError();
}

void main() {
  group('StickerId', () {
    test('the nine wire ids are exact and in API order', () {
      expect(StickerId.supported.map((StickerId id) => id.wireId), <String>[
        'gg',
        'fire',
        'facepalm',
        'lol',
        'hmm',
        'too_slow',
        'ez',
        'wait_what',
        'crying',
      ]);
      expect(StickerId.supported, isNot(contains(StickerId.unknown)));
    });

    test('fromWire is exact: no case folding, no aliases', () {
      expect(StickerId.fromWire('too_slow'), StickerId.tooSlow);
      expect(StickerId.fromWire('GG'), StickerId.unknown);
      expect(StickerId.fromWire('tooSlow'), StickerId.unknown);
      expect(StickerId.fromWire(''), StickerId.unknown);
      expect(StickerId.fromWire('future_sticker_id'), StickerId.unknown);
    });
  });

  group('SendStickerUsecase', () {
    test('rejects an unknown sticker without a request', () async {
      final _Repository repository = _Repository();

      final Either<Failure, StickerReceiptEntity> result =
          await SendStickerUsecase(repository)(
            const SendStickerParamsEntity(
              battleId: 'b1',
              stickerId: StickerId.unknown,
              submissionId: 's1',
            ),
          );

      expect(result.getLeft(), isA<ValidationFailure>());
      expect(repository.sends, isEmpty);
    });

    test('forwards a known sticker and its result unchanged', () async {
      final _Repository repository = _Repository();
      const SendStickerParamsEntity params = SendStickerParamsEntity(
        battleId: 'b1',
        stickerId: StickerId.ez,
        submissionId: 's1',
      );

      final Either<Failure, StickerReceiptEntity> result =
          await SendStickerUsecase(repository)(params);

      expect(repository.sends.single, params);
      expect(result.getLeft(), const TimeoutFailure());
    });
  });

  group('models', () {
    test('the request body has exactly the wire id and the submission id', () {
      expect(
        StickerRequestModel.fromEntity(
          const SendStickerParamsEntity(
            battleId: 'b1',
            stickerId: StickerId.waitWhat,
            submissionId: 's1',
          ),
        ).toJson(),
        <String, dynamic>{'stickerId': 'wait_what', 'submissionId': 's1'},
      );
    });

    test('a receipt without nextAllowedAt is malformed', () {
      expect(
        () => StickerReceiptModel.fromJson(<String, dynamic>{
          'battleId': 'b1',
          'submissionId': 's1',
          'senderUserId': 'u1',
          'stickerId': 'gg',
          'sentAt': '2026-11-15T03:00:00Z',
        }),
        throwsA(isA<CheckedFromJsonException>()),
      );
    });

    test('an incoming payload with a future sticker id still parses', () {
      final IncomingStickerEntity entity = BattleStickerModel.fromJson(
        <String, dynamic>{
          'battleId': 'b1',
          'submissionId': 's1',
          'senderUserId': 'u1',
          'stickerId': 'future_sticker_id',
          'sentAt': '2026-11-15T03:00:00Z',
        },
      ).toEntity(eventId: 'e1', sequence: 2);

      expect(entity.stickerId, StickerId.unknown);
      expect(entity.sequence, 2);
    });
  });

  test('a BATTLE_STICKER envelope is parsed by the realtime client', () {
    final RealtimeEnvelope? envelope = RealtimeEnvelope.tryParse(
      '{"eventId":"e1","type":"BATTLE_STICKER","resourceId":"b1","version":1,'
      '"occurredAt":"2026-11-15T03:00:00Z","data":{"battleId":"b1",'
      '"submissionId":"s1","senderUserId":"u1","stickerId":"gg",'
      '"sentAt":"2026-11-15T03:00:00Z"}}',
    );

    expect(envelope?.type, RealtimeEventType.battleSticker);
    expect(envelope?.version, 1);
  });
}
