import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/subscription/domain/entity/subscription_plan_entity.dart';
import 'package:skill_battles/features/subscription/domain/repository/subscription_repository.dart';

final class GetPlansUsecase
    implements
        Usecase<
          Future<Either<Failure, List<SubscriptionPlanEntity>>>,
          NoParams
        > {
  const GetPlansUsecase(this._repository);

  final SubscriptionRepository _repository;

  @override
  Future<Either<Failure, List<SubscriptionPlanEntity>>> call(NoParams params) =>
      _repository.getPlans();
}
