import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/plan_code_model.dart';
import 'package:skill_battles/features/subscription/data/models/plan_interval_model.dart';
import 'package:skill_battles/features/subscription/domain/entity/subscription_plan_entity.dart';

part 'subscription_plan_model.g.dart';

/// Plan offered to the user.
@JsonSerializable(checked: true, createToJson: false)
final class SubscriptionPlanModel {
  const SubscriptionPlanModel({
    required this.code,
    required this.name,
    required this.amountCents,
    required this.currency,
    required this.interval,
    required this.intervalCount,
    required this.monthlyEquivalentCents,
    required this.annualSavingsPercent,
    required this.checkoutAvailable,
    required this.features,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPlanModelFromJson(json);

  @JsonKey(required: true)
  final PlanCodeModel code;

  @JsonKey(required: true)
  final String name;

  @JsonKey(required: true)
  final int amountCents;

  @JsonKey(required: true)
  final String currency;

  @JsonKey(required: true)
  final PlanIntervalModel interval;

  @JsonKey(required: true)
  final int intervalCount;

  @JsonKey(required: true)
  final int monthlyEquivalentCents;

  @JsonKey(required: true)
  final int annualSavingsPercent;

  @JsonKey(required: true)
  final bool checkoutAvailable;

  @JsonKey(required: true)
  final List<String> features;

  SubscriptionPlanEntity toEntity() => SubscriptionPlanEntity(
    code: code.toEntity(),
    name: name,
    amountCents: amountCents,
    currency: currency,
    interval: interval.toEntity(),
    monthlyEquivalentCents: monthlyEquivalentCents,
    annualSavingsPercent: annualSavingsPercent,
    checkoutAvailable: checkoutAvailable,
    features: List<String>.unmodifiable(features),
  );
}
