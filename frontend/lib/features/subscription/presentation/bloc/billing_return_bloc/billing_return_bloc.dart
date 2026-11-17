import 'dart:async';

import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/subscription_entity.dart';
import 'package:skill_battles/core/domain/entity/subscription_status.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/presentation/bloc/signal_bloc.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/subscription/domain/usecases/get_subscription_usecase.dart';

part 'billing_return_event.dart';
part 'billing_return_state.dart';

/// After Stripe sends the browser back. The query string proves nothing:
/// Pro is shown only when the server reports a verified ACTIVE status, so
/// this polls `GET /subscriptions/me` for a while.
final class BillingReturnBloc
    extends SignalBloc<BillingReturnEvent, BillingReturnState> {
  BillingReturnBloc({
    required this._getSubscription,
    this.pollInterval = const Duration(seconds: 2),
    this.maxAttempts = 15,
  }) : super(const BillingReturnState()) {
    handle<BillingReturnStarted>(_onStarted, transformer: droppable());
    handle<_BillingPollTick>(_onTick, transformer: droppable());
  }

  final GetSubscriptionUsecase _getSubscription;
  final Duration pollInterval;
  final int maxAttempts;

  Timer? _timer;

  Future<void> _onStarted(
    BillingReturnStarted event,
    Emitter<BillingReturnState> emit,
  ) async {
    emit(
      BillingReturnState(
        status: event.checkoutCancelled
            ? BillingReturnStatus.cancelled
            : BillingReturnStatus.checking,
      ),
    );
    await _check(emit);
  }

  Future<void> _onTick(
    _BillingPollTick event,
    Emitter<BillingReturnState> emit,
  ) => _check(emit);

  Future<void> _check(Emitter<BillingReturnState> emit) async {
    final Either<Failure, SubscriptionEntity> result = await _getSubscription(
      const NoParams(),
    );
    if (emit.isDone) return;
    final int attempts = stateValue.attempts + 1;
    result.match(
      (Failure failure) =>
          emit(stateValue.copyWith(attempts: attempts, failure: failure)),
      (SubscriptionEntity subscription) {
        final bool active =
            subscription.status == SubscriptionStatus.active &&
            subscription.entitlements.isPro;
        emit(
          stateValue.copyWith(
            attempts: attempts,
            subscription: subscription,
            status: active
                ? BillingReturnStatus.active
                : stateValue.status == BillingReturnStatus.cancelled
                ? BillingReturnStatus.cancelled
                : attempts >= maxAttempts
                ? BillingReturnStatus.pending
                : BillingReturnStatus.checking,
            resetFailure: true,
          ),
        );
      },
    );
    _timer?.cancel();
    if (stateValue.status == BillingReturnStatus.checking &&
        attempts < maxAttempts) {
      _timer = Timer(pollInterval, () {
        if (!isClosed) add(const _BillingPollTick());
      });
    } else if (stateValue.status == BillingReturnStatus.checking) {
      emit(stateValue.copyWith(status: BillingReturnStatus.pending));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
