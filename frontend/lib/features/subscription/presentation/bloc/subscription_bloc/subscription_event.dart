part of 'subscription_bloc.dart';

sealed class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => <Object?>[];
}

final class SubscriptionStarted extends SubscriptionEvent {
  const SubscriptionStarted();
}

final class SubscriptionRefreshRequested extends SubscriptionEvent {
  const SubscriptionRefreshRequested();
}

final class SubscriptionCheckoutRequested extends SubscriptionEvent {
  const SubscriptionCheckoutRequested(this.planCode);

  final PlanCode planCode;

  @override
  List<Object?> get props => <Object?>[planCode];
}

final class SubscriptionPortalRequested extends SubscriptionEvent {
  const SubscriptionPortalRequested();
}
