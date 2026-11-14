import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/battle_result/domain/entity/battle_review_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/review_params_entity.dart';
import 'package:skill_battles/features/battle_result/domain/repository/battle_result_repository.dart';

final class GetReviewUsecase
    implements
        Usecase<
          Future<Either<Failure, BattleReviewEntity>>,
          ReviewParamsEntity
        > {
  const GetReviewUsecase(this._repository);

  final BattleResultRepository _repository;

  @override
  Future<Either<Failure, BattleReviewEntity>> call(ReviewParamsEntity params) =>
      _repository.getReview(params);
}
