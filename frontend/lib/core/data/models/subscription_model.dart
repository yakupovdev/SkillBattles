import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/entitlements_model.dart';
import 'package:skill_battles/core/data/models/plan_code_model.dart';
import 'package:skill_battles/core/data/models/subscription_status_model.dart';
import 'package:skill_battles/core/domain/entity/subscription_entity.dart';

part 'subscription_model.g.dart';

/// Current verified subscription and rights.
@JsonSerializable(checked: true, createToJson: false)
final class SubscriptionModel {
  const SubscriptionModel({
    required this.planCode,
    required this.status,
    required this.billingMode,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
    required this.entitlements,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionModelFromJson(json);

  @JsonKey(required: true)
  final PlanCodeModel planCode;

  @JsonKey(required: true)
  final SubscriptionStatusModel status;

  @JsonKey(required: true)
  final String billingMode;

  @JsonKey(required: true)
  final DateTime? currentPeriodStart;

  @JsonKey(required: true)
  final DateTime? currentPeriodEnd;

  @JsonKey(required: true)
  final bool cancelAtPeriodEnd;

  @JsonKey(required: true)
  final EntitlementsModel entitlements;

  static const String testBillingMode = 'TEST';

  SubscriptionEntity toEntity() => SubscriptionEntity(
    planCode: planCode.toEntity(),
    status: status.toEntity(),
    isTestMode: billingMode == testBillingMode,
    currentPeriodStart: currentPeriodStart,
    currentPeriodEnd: currentPeriodEnd,
    cancelAtPeriodEnd: cancelAtPeriodEnd,
    entitlements: entitlements.toEntity(),
  );
}
