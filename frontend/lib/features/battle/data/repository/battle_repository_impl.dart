import 'dart:developer' as developer;

import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/repository/realtime_decode.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/error/failure_mapper.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/core/utils/realtime/realtime_client.dart';
import 'package:skill_battles/core/utils/realtime/realtime_envelope.dart';
import 'package:skill_battles/core/utils/session/auth_session.dart';
import 'package:skill_battles/core/utils/time/clock.dart';
import 'package:skill_battles/features/battle/data/models/answer_receipt_model.dart';
import 'package:skill_battles/features/battle/data/models/answer_request_model.dart';
import 'package:skill_battles/features/battle/data/models/battle_snapshot_model.dart';
import 'package:skill_battles/features/battle/data/models/battle_sticker_model.dart';
import 'package:skill_battles/features/battle/data/models/sticker_receipt_model.dart';
import 'package:skill_battles/features/battle/data/models/sticker_request_model.dart';
import 'package:skill_battles/features/battle/data/sources/remote/battle_remote.dart';
import 'package:skill_battles/features/battle/domain/entity/answer_receipt_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_snapshot_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/incoming_sticker_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/send_sticker_params_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_receipt_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/submit_answer_params_entity.dart';
import 'package:skill_battles/features/battle/domain/repository/battle_repository.dart';

/// Remote, BATTLE_CHANGED and BATTLE_STICKER events. Snapshots hold answers
/// and paid fields personalised for this reader, so they are never cached.
/// Stickers are ephemeral: sends are not cached or queued, and incoming
/// stickers have no history (nothing is replayed after a reconnect).
final class BattleRepositoryImpl implements BattleRepository {
  const BattleRepositoryImpl({
    required this._remote,
    required this._realtime,
    required this._session,
    required this._clock,
  });

  final BattleRemote _remote;
  final RealtimeClient _realtime;
  final AuthSession _session;
  final Clock _clock;

  BattleSnapshotEntity _map(BattleSnapshotModel model) =>
      model.toEntity(myUserId: _session.userId ?? '', receivedAt: _clock.now());

  @override
  Future<Either<Failure, BattleSnapshotEntity>> getBattle(
    String battleId,
  ) async {
    try {
      final BattleSnapshotModel model = await _remote.getBattle(battleId);
      return Right(_map(model));
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, BattleSnapshotEntity>> setReady(
    String battleId,
  ) async {
    try {
      final BattleSnapshotModel model = await _remote.setReady(battleId);
      return Right(_map(model));
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, AnswerReceiptEntity>> submitAnswer(
    SubmitAnswerParamsEntity params,
  ) async {
    try {
      final AnswerReceiptModel model = await _remote.submitAnswer(
        params.battleId,
        AnswerRequestModel.fromEntity(params),
      );
      return Right(model.toEntity());
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, BattleSnapshotEntity>> surrender(
    String battleId,
  ) async {
    try {
      final BattleSnapshotModel model = await _remote.surrender(battleId);
      return Right(_map(model));
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Stream<BattleSnapshotEntity> watchBattle(String battleId) =>
      decodeRealtime<BattleSnapshotEntity>(
        _realtime.events,
        type: RealtimeEventType.battleChanged,
        where: (RealtimeEnvelope event) => event.resourceId == battleId,
        parse: (Map<String, dynamic> data) =>
            _map(BattleSnapshotModel.fromJson(data)),
      );

  @override
  Future<Either<Failure, StickerReceiptEntity>> sendSticker(
    SendStickerParamsEntity params,
  ) async {
    try {
      final StickerReceiptModel model = await _remote.sendSticker(
        params.battleId,
        StickerRequestModel.fromEntity(params),
      );
      return Right(model.toEntity());
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  /// The sticker sequence and the event id live in the envelope, so the
  /// payload is mapped here instead of through `decodeRealtime`. Events whose
  /// payload names another battle than the envelope are dropped.
  @override
  Stream<IncomingStickerEntity> watchStickers(String battleId) => _realtime
      .events
      .where(
        (RealtimeEnvelope event) =>
            event.type == RealtimeEventType.battleSticker &&
            event.resourceId == battleId,
      )
      .expand((RealtimeEnvelope event) {
        try {
          final BattleStickerModel model = BattleStickerModel.fromJson(
            event.data,
          );
          if (model.battleId != event.resourceId) {
            return const <IncomingStickerEntity>[];
          }
          return <IncomingStickerEntity>[
            model.toEntity(eventId: event.eventId, sequence: event.version),
          ];
        } on CheckedFromJsonException catch (error) {
          developer.log(
            'Malformed ${event.type.wireName} '
            '(${error.className}.${error.key})',
            name: 'realtime',
          );
          return const <IncomingStickerEntity>[];
        }
      });
}
