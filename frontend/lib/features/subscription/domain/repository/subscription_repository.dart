import 'package:skill_battles/core/domain/entity/subscription_entity.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/subscription/domain/entity/checkout_entity.dart';
import 'package:skill_battles/features/subscription/domain/entity/start_checkout_params_entity.dart';
import 'package:skill_battles/features/subscription/domain/entity/subscription_plan_entity.dart';

abstract interface class SubscriptionRepository {
  Future<Either<Failure, List<SubscriptionPlanEntity>>> getPlans();

  /// The verified provider state; the success URL alone never activates Pro.
  Future<Either<Failure, SubscriptionEntity>> getSubscription();

  Future<Either<Failure, CheckoutEntity>> startCheckout(
    StartCheckoutParamsEntity params,
  );

  /// URL of this account's Stripe Customer Portal.
  Future<Either<Failure, String>> openPortal();
}
