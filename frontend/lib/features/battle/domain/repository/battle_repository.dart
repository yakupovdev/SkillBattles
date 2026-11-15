import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/battle/domain/entity/answer_receipt_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_snapshot_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/incoming_sticker_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/send_sticker_params_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_receipt_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/submit_answer_params_entity.dart';

abstract interface class BattleRepository {
  Future<Either<Failure, BattleSnapshotEntity>> getBattle(String battleId);

  Future<Either<Failure, BattleSnapshotEntity>> setReady(String battleId);

  Future<Either<Failure, AnswerReceiptEntity>> submitAnswer(
    SubmitAnswerParamsEntity params,
  );

  /// Cancels before the first question, forfeits afterwards.
  Future<Either<Failure, BattleSnapshotEntity>> surrender(String battleId);

  /// BATTLE_CHANGED snapshots of [battleId], personalised for this reader.
  Stream<BattleSnapshotEntity> watchBattle(String battleId);

  /// POST /battles/{id}/stickers. The same [SendStickerParamsEntity.submissionId]
  /// returns the original receipt for 120 s without a second event.
  Future<Either<Failure, StickerReceiptEntity>> sendSticker(
    SendStickerParamsEntity params,
  );

  /// BATTLE_STICKER events of [battleId] from the existing realtime client.
  /// Unknown sticker ids arrive as [StickerId.unknown]; malformed events are
  /// skipped. No history: missed events are never replayed.
  Stream<IncomingStickerEntity> watchStickers(String battleId);
}
