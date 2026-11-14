// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionModel _$SubscriptionModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SubscriptionModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'planCode',
          'status',
          'billingMode',
          'currentPeriodStart',
          'currentPeriodEnd',
          'cancelAtPeriodEnd',
          'entitlements',
        ],
      );
      final val = SubscriptionModel(
        planCode: $checkedConvert(
          'planCode',
          (v) => $enumDecode(_$PlanCodeModelEnumMap, v),
        ),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$SubscriptionStatusModelEnumMap, v),
        ),
        billingMode: $checkedConvert('billingMode', (v) => v as String),
        currentPeriodStart: $checkedConvert(
          'currentPeriodStart',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
        currentPeriodEnd: $checkedConvert(
          'currentPeriodEnd',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
        cancelAtPeriodEnd: $checkedConvert(
          'cancelAtPeriodEnd',
          (v) => v as bool,
        ),
        entitlements: $checkedConvert(
          'entitlements',
          (v) => EntitlementsModel.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

const _$PlanCodeModelEnumMap = {
  PlanCodeModel.free: 'FREE',
  PlanCodeModel.proMonthly: 'PRO_MONTHLY',
  PlanCodeModel.proAnnual: 'PRO_ANNUAL',
};

const _$SubscriptionStatusModelEnumMap = {
  SubscriptionStatusModel.none: 'NONE',
  SubscriptionStatusModel.incomplete: 'INCOMPLETE',
  SubscriptionStatusModel.active: 'ACTIVE',
  SubscriptionStatusModel.pastDue: 'PAST_DUE',
  SubscriptionStatusModel.canceled: 'CANCELED',
  SubscriptionStatusModel.unpaid: 'UNPAID',
  SubscriptionStatusModel.expired: 'EXPIRED',
};
