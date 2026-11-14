import 'package:skill_battles/core/domain/entity/plan_code.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/subscription/domain/entity/checkout_entity.dart';
import 'package:skill_battles/features/subscription/domain/entity/start_checkout_params_entity.dart';
import 'package:skill_battles/features/subscription/domain/repository/subscription_repository.dart';

/// Free is not purchasable.
final class StartCheckoutUsecase
    implements
        Usecase<
          Future<Either<Failure, CheckoutEntity>>,
          StartCheckoutParamsEntity
        > {
  const StartCheckoutUsecase(this._repository);

  final SubscriptionRepository _repository;

  @override
  Future<Either<Failure, CheckoutEntity>> call(
    StartCheckoutParamsEntity params,
  ) async {
    if (params.planCode == PlanCode.free) {
      return const Left(ValidationFailure(message: 'Choose a Pro plan.'));
    }
    return _repository.startCheckout(params);
  }
}
