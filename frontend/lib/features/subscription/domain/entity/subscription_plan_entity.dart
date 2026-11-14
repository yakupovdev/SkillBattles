import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/plan_code.dart';
import 'package:skill_battles/features/subscription/domain/entity/plan_interval.dart';

/// A plan from `GET /subscriptions/plans`; prices are server-owned.
final class SubscriptionPlanEntity extends Equatable {
  const SubscriptionPlanEntity({
    required this.code,
    required this.name,
    required this.amountCents,
    required this.currency,
    required this.interval,
    required this.monthlyEquivalentCents,
    required this.annualSavingsPercent,
    required this.checkoutAvailable,
    required this.features,
  });

  final PlanCode code;
  final String name;
  final int amountCents;
  final String currency;
  final PlanInterval interval;

  /// Display only (annual: 400 cents).
  final int monthlyEquivalentCents;
  final int annualSavingsPercent;

  /// `false` when test billing is not configured; Free is never purchasable.
  final bool checkoutAvailable;
  final List<String> features;

  @override
  List<Object?> get props => <Object?>[
    code,
    name,
    amountCents,
    currency,
    interval,
    monthlyEquivalentCents,
    annualSavingsPercent,
    checkoutAvailable,
    features,
  ];
}
