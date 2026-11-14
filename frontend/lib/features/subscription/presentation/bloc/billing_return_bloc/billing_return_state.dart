part of 'billing_return_bloc.dart';

enum BillingReturnStatus {
  /// Waiting for the verified provider state.
  checking,

  /// Verified ACTIVE: Pro is on.
  active,

  /// Not confirmed yet (unpaid invoice, slow webhook).
  pending,

  /// Checkout was left without paying.
  cancelled,
}

final class BillingReturnState extends Equatable {
  const BillingReturnState({
    this.status = BillingReturnStatus.checking,
    this.subscription,
    this.attempts = 0,
    this.failure,
  });

  final BillingReturnStatus status;
  final SubscriptionEntity? subscription;
  final int attempts;
  final Failure? failure;

  BillingReturnState copyWith({
    BillingReturnStatus? status,
    SubscriptionEntity? subscription,
    int? attempts,
    Failure? failure,
    bool resetFailure = false,
  }) {
    return BillingReturnState(
      status: status ?? this.status,
      subscription: subscription ?? this.subscription,
      attempts: attempts ?? this.attempts,
      failure: resetFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, subscription, attempts, failure];
}
