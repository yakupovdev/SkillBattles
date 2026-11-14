import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:skill_battles/core/domain/entity/subscription_entity.dart';
import 'package:skill_battles/core/domain/entity/subscription_status.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/subscription/domain/usecases/get_subscription_usecase.dart';

part 'billing_return_event.dart';
part 'billing_return_state.dart';

/// After Stripe sends the browser back. The query string proves nothing:
/// Pro is shown only when the server reports a verified ACTIVE status, so
/// this polls `GET /subscriptions/me` for a while.
final class BillingReturnBloc
    extends Bloc<BillingReturnEvent, BillingReturnState> {
  BillingReturnBloc({
    required this._getSubscription,
    this.pollInterval = const Duration(seconds: 2),
    this.maxAttempts = 15,
  }) : super(const BillingReturnState()) {
    on<BillingReturnStarted>(_onStarted, transformer: droppable());
    on<_BillingPollTick>(_onTick, transformer: droppable());
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
    final int attempts = state.attempts + 1;
    result.match(
      (Failure failure) =>
          emit(state.copyWith(attempts: attempts, failure: failure)),
      (SubscriptionEntity subscription) {
        final bool active =
            subscription.status == SubscriptionStatus.active &&
            subscription.entitlements.isPro;
        emit(
          state.copyWith(
            attempts: attempts,
            subscription: subscription,
            status: active
                ? BillingReturnStatus.active
                : state.status == BillingReturnStatus.cancelled
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
    if (state.status == BillingReturnStatus.checking &&
        attempts < maxAttempts) {
      _timer = Timer(pollInterval, () {
        if (!isClosed) add(const _BillingPollTick());
      });
    } else if (state.status == BillingReturnStatus.checking) {
      emit(state.copyWith(status: BillingReturnStatus.pending));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
