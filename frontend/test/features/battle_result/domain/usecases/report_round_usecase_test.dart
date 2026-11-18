import 'package:test/test.dart';

import 'package:skill_battles/core/domain/entity/battle_result_entity.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/battle_result/domain/entity/battle_review_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/rematch_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/report_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/report_params_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/report_reason.dart';
import 'package:skill_battles/features/battle_result/domain/entity/review_params_entity.dart';
import 'package:skill_battles/features/battle_result/domain/repository/battle_result_repository.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/report_round_usecase.dart';

final class _Repository implements BattleResultRepository {
  int reports = 0;

  @override
  Future<Either<Failure, ReportEntity>> reportRound(
    ReportParamsEntity params,
  ) async {
    reports++;
    return Right(
      ReportEntity(
        id: 'r',
        roundId: params.roundId,
        createdAt: DateTime.utc(2026),
      ),
    );
  }

  @override
  Future<Either<Failure, BattleResultEntity>> getResult(String battleId) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, BattleReviewEntity>> getReview(
    ReviewParamsEntity params,
  ) => throw UnimplementedError();

  @override
  Future<Either<Failure, RematchEntity?>> getRematch(String battleId) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, RematchEntity>> requestRematch(String battleId) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, Unit>> cancelRematch(String battleId) =>
      throw UnimplementedError();

  @override
  Stream<RematchEntity> watchRematch(String battleId) =>
      const Stream<RematchEntity>.empty();

  @override
  Stream<RematchEntity> watchRematches() => const Stream<RematchEntity>.empty();
}

void main() {
  test('"Other" without a comment is rejected locally', () async {
    final _Repository repository = _Repository();

    final Either<Failure, ReportEntity> result =
        await ReportRoundUsecase(repository)(
          const ReportParamsEntity(
            battleId: 'b',
            roundId: 'r',
            reason: ReportReason.other,
            comment: '  ',
          ),
        );

    expect(result.getLeft(), isA<ValidationFailure>());
    expect(repository.reports, 0);
  });

  test('a reason without a comment is sent', () async {
    final _Repository repository = _Repository();

    final Either<Failure, ReportEntity> result =
        await ReportRoundUsecase(repository)(
          const ReportParamsEntity(
            battleId: 'b',
            roundId: 'r',
            reason: ReportReason.typo,
          ),
        );

    expect(result.isRight(), isTrue);
    expect(repository.reports, 1);
  });
}
