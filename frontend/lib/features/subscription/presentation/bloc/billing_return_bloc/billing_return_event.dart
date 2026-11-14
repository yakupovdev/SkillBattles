part of 'billing_return_bloc.dart';

sealed class BillingReturnEvent extends Equatable {
  const BillingReturnEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// [checkoutCancelled] when Stripe returned through the cancel URL.
final class BillingReturnStarted extends BillingReturnEvent {
  const BillingReturnStarted({required this.checkoutCancelled});

  final bool checkoutCancelled;

  @override
  List<Object?> get props => <Object?>[checkoutCancelled];
}

final class _BillingPollTick extends BillingReturnEvent {
  const _BillingPollTick();
}
