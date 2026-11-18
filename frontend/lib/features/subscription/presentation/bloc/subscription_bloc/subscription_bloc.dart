import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/plan_code.dart';
import 'package:skill_battles/core/domain/entity/subscription_entity.dart';
import 'package:skill_battles/core/domain/usecases/generate_id_usecase.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/presentation/bloc/load_status.dart';
import 'package:skill_battles/core/presentation/bloc/signal_bloc.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/subscription/domain/entity/checkout_entity.dart';
import 'package:skill_battles/features/subscription/domain/entity/start_checkout_params_entity.dart';
import 'package:skill_battles/features/subscription/domain/entity/subscription_plan_entity.dart';
import 'package:skill_battles/features/subscription/domain/usecases/get_plans_usecase.dart';
import 'package:skill_battles/features/subscription/domain/usecases/get_subscription_usecase.dart';
import 'package:skill_battles/features/subscription/domain/usecases/open_portal_usecase.dart';
import 'package:skill_battles/features/subscription/domain/usecases/start_checkout_usecase.dart';

part 'subscription_event.dart';
part 'subscription_state.dart';

/// Plans, the verified subscription, Stripe test Checkout and the
/// Customer Portal. The page to open is published as [SubscriptionState.
/// externalUrl]; the screen opens it.
final class SubscriptionBloc
    extends SignalBloc<SubscriptionEvent, SubscriptionState> {
  SubscriptionBloc({
    required this._getPlans,
    required this._getSubscription,
    required this._startCheckout,
    required this._openPortal,
    required this._generateId,
  }) : super(const SubscriptionState()) {
    handle<SubscriptionStarted>(_onStarted, transformer: restartable());
    handle<SubscriptionRefreshRequested>(_onStarted, transformer: restartable());
    handle<SubscriptionCheckoutRequested>(_onCheckout, transformer: droppable());
    handle<SubscriptionPortalRequested>(_onPortal, transformer: droppable());
  }

  final GetPlansUsecase _getPlans;
  final GetSubscriptionUsecase _getSubscription;
  final StartCheckoutUsecase _startCheckout;
  final OpenPortalUsecase _openPortal;
  final GenerateIdUsecase _generateId;

  Future<void> _onStarted(
    SubscriptionEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(stateValue.copyWith(loadStatus: LoadStatus.loading));
    final (
      Either<Failure, List<SubscriptionPlanEntity>> plans,
      Either<Failure, SubscriptionEntity> subscription,
    ) = await (
      _getPlans(const NoParams()),
      _getSubscription(const NoParams()),
    ).wait;
    if (emit.isDone) return;
    final Failure? failure = plans.getLeft() ?? subscription.getLeft();
    if (failure != null) {
      emit(stateValue.copyWith(loadStatus: LoadStatus.failure, failure: failure));
      return;
    }
    emit(
      stateValue.copyWith(
        loadStatus: LoadStatus.success,
        plans: plans.toNullable(),
        subscription: subscription.toNullable(),
        resetFailure: true,
      ),
    );
  }

  Future<void> _onCheckout(
    SubscriptionCheckoutRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    // One id per purchase attempt, kept for retries of the same plan.
    final String requestId =
        stateValue.requestIds[event.planCode] ?? _generateId(const NoParams());
    emit(
      stateValue.copyWith(
        checkoutStatus: LoadStatus.loading,
        checkoutPlan: event.planCode,
        requestIds: <PlanCode, String>{
          ...stateValue.requestIds,
          event.planCode: requestId,
        },
        resetCheckoutFailure: true,
      ),
    );
    final Either<Failure, CheckoutEntity> result = await _startCheckout(
      StartCheckoutParamsEntity(planCode: event.planCode, requestId: requestId),
    );
    if (emit.isDone) return;
    await result.match(
      (Failure failure) async {
        emit(
          stateValue.copyWith(
            checkoutStatus: LoadStatus.failure,
            checkoutFailure: failure,
          ),
        );
        if (failure.hasCode(ApiErrorCodes.subscriptionAlreadyActive)) {
          add(const SubscriptionRefreshRequested());
        }
      },
      (CheckoutEntity checkout) async => emit(
        stateValue.copyWith(
          checkoutStatus: LoadStatus.success,
          externalUrl: checkout.url,
          externalUrlSerial: stateValue.externalUrlSerial + 1,
        ),
      ),
    );
  }

  Future<void> _onPortal(
    SubscriptionPortalRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(
      stateValue.copyWith(
        portalStatus: LoadStatus.loading,
        resetPortalFailure: true,
      ),
    );
    final Either<Failure, String> result = await _openPortal(const NoParams());
    if (emit.isDone) return;
    result.match(
      (Failure failure) => emit(
        stateValue.copyWith(
          portalStatus: LoadStatus.failure,
          portalFailure: failure,
        ),
      ),
      (String url) => emit(
        stateValue.copyWith(
          portalStatus: LoadStatus.success,
          externalUrl: url,
          externalUrlSerial: stateValue.externalUrlSerial + 1,
        ),
      ),
    );
  }
}
