import 'package:skill_battles/core/data/models/plan_code_model.dart';
import 'package:skill_battles/core/data/models/subscription_model.dart';
import 'package:skill_battles/core/domain/entity/subscription_entity.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/error/failure_mapper.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/subscription/data/models/checkout_model.dart';
import 'package:skill_battles/features/subscription/data/models/checkout_request_model.dart';
import 'package:skill_battles/features/subscription/data/models/portal_model.dart';
import 'package:skill_battles/features/subscription/data/models/subscription_plan_model.dart';
import 'package:skill_battles/features/subscription/data/sources/remote/subscription_remote.dart';
import 'package:skill_battles/features/subscription/domain/entity/checkout_entity.dart';
import 'package:skill_battles/features/subscription/domain/entity/start_checkout_params_entity.dart';
import 'package:skill_battles/features/subscription/domain/entity/subscription_plan_entity.dart';
import 'package:skill_battles/features/subscription/domain/repository/subscription_repository.dart';

/// Remote only; billing answers are `no-store`.
final class SubscriptionRepositoryImpl implements SubscriptionRepository {
  const SubscriptionRepositoryImpl({required this._remote});

  final SubscriptionRemote _remote;

  @override
  Future<Either<Failure, List<SubscriptionPlanEntity>>> getPlans() async {
    try {
      final List<SubscriptionPlanModel> models = await _remote.getPlans();
      return Right(
        models
            .map((SubscriptionPlanModel plan) => plan.toEntity())
            .toList(growable: false),
      );
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, SubscriptionEntity>> getSubscription() async {
    try {
      final SubscriptionModel model = await _remote.getMySubscription();
      return Right(model.toEntity());
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, CheckoutEntity>> startCheckout(
    StartCheckoutParamsEntity params,
  ) async {
    try {
      final CheckoutModel model = await _remote.createCheckout(
        CheckoutRequestModel(
          planCode: PlanCodeModel.fromEntity(params.planCode),
          requestId: params.requestId,
        ),
      );
      return Right(model.toEntity());
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, String>> openPortal() async {
    try {
      final PortalModel model = await _remote.createPortal();
      return Right(model.url);
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }
}
