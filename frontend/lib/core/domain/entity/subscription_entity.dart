import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/entitlements_entity.dart';
import 'package:skill_battles/core/domain/entity/plan_code.dart';
import 'package:skill_battles/core/domain/entity/subscription_status.dart';

/// Current verified subscription of the account (Stripe TEST mode only).
final class SubscriptionEntity extends Equatable {
  const SubscriptionEntity({
    required this.planCode,
    required this.status,
    required this.isTestMode,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
    required this.entitlements,
  });

  final PlanCode planCode;
  final SubscriptionStatus status;
  final bool isTestMode;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;

  /// Access stays until [currentPeriodEnd] when a cancellation is scheduled.
  final bool cancelAtPeriodEnd;
  final EntitlementsEntity entitlements;

  @override
  List<Object?> get props => <Object?>[
    planCode,
    status,
    isTestMode,
    currentPeriodStart,
    currentPeriodEnd,
    cancelAtPeriodEnd,
    entitlements,
  ];
}
