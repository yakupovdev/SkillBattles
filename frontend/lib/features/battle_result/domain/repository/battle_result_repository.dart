import 'package:skill_battles/core/domain/entity/battle_result_entity.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/battle_result/domain/entity/battle_review_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/rematch_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/report_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/report_params_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/review_params_entity.dart';

abstract interface class BattleResultRepository {
  /// 403 `HISTORY_ACCESS_REQUIRED` for an own match outside the Free window.
  Future<Either<Failure, BattleResultEntity>> getResult(String battleId);

  Future<Either<Failure, BattleReviewEntity>> getReview(
    ReviewParamsEntity params,
  );

  /// `null` before the first consent.
  Future<Either<Failure, RematchEntity?>> getRematch(String battleId);

  /// Repeats return the same state; one consent never starts a game.
  Future<Either<Failure, RematchEntity>> requestRematch(String battleId);

  Future<Either<Failure, Unit>> cancelRematch(String battleId);

  /// An exact repeat returns the existing report.
  Future<Either<Failure, ReportEntity>> reportRound(ReportParamsEntity params);

  Stream<RematchEntity> watchRematch(String battleId);
}
