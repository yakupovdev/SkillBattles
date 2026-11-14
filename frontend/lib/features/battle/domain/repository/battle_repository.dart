import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/battle/domain/entity/answer_receipt_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_snapshot_entity.dart';
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
}
