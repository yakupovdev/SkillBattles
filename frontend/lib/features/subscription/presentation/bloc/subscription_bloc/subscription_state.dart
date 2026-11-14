part of 'subscription_bloc.dart';

final class SubscriptionState extends Equatable {
  const SubscriptionState({
    this.loadStatus = LoadStatus.initial,
    this.failure,
    this.plans = const <SubscriptionPlanEntity>[],
    this.subscription,
    this.checkoutStatus = LoadStatus.initial,
    this.checkoutPlan,
    this.checkoutFailure,
    this.requestIds = const <PlanCode, String>{},
    this.portalStatus = LoadStatus.initial,
    this.portalFailure,
    this.externalUrl,
    this.externalUrlSerial = 0,
  });

  final LoadStatus loadStatus;
  final Failure? failure;
  final List<SubscriptionPlanEntity> plans;
  final SubscriptionEntity? subscription;
  final LoadStatus checkoutStatus;
  final PlanCode? checkoutPlan;
  final Failure? checkoutFailure;

  /// Checkout idempotency key per plan for the current attempt.
  final Map<PlanCode, String> requestIds;
  final LoadStatus portalStatus;
  final Failure? portalFailure;

  /// Provider page to open; [externalUrlSerial] changes on every request.
  final String? externalUrl;
  final int externalUrlSerial;

  SubscriptionState copyWith({
    LoadStatus? loadStatus,
    Failure? failure,
    List<SubscriptionPlanEntity>? plans,
    SubscriptionEntity? subscription,
    LoadStatus? checkoutStatus,
    PlanCode? checkoutPlan,
    Failure? checkoutFailure,
    Map<PlanCode, String>? requestIds,
    LoadStatus? portalStatus,
    Failure? portalFailure,
    String? externalUrl,
    int? externalUrlSerial,
    bool resetFailure = false,
    bool resetCheckoutFailure = false,
    bool resetPortalFailure = false,
  }) {
    return SubscriptionState(
      loadStatus: loadStatus ?? this.loadStatus,
      failure: resetFailure ? null : failure ?? this.failure,
      plans: plans ?? this.plans,
      subscription: subscription ?? this.subscription,
      checkoutStatus: checkoutStatus ?? this.checkoutStatus,
      checkoutPlan: checkoutPlan ?? this.checkoutPlan,
      checkoutFailure: resetCheckoutFailure
          ? null
          : checkoutFailure ?? this.checkoutFailure,
      requestIds: requestIds ?? this.requestIds,
      portalStatus: portalStatus ?? this.portalStatus,
      portalFailure: resetPortalFailure
          ? null
          : portalFailure ?? this.portalFailure,
      externalUrl: externalUrl ?? this.externalUrl,
      externalUrlSerial: externalUrlSerial ?? this.externalUrlSerial,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    loadStatus,
    failure,
    plans,
    subscription,
    checkoutStatus,
    checkoutPlan,
    checkoutFailure,
    requestIds,
    portalStatus,
    portalFailure,
    externalUrl,
    externalUrlSerial,
  ];
}
