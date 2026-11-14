// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_plan_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionPlanModel _$SubscriptionPlanModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SubscriptionPlanModel', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'code',
      'name',
      'amountCents',
      'currency',
      'interval',
      'intervalCount',
      'monthlyEquivalentCents',
      'annualSavingsPercent',
      'checkoutAvailable',
      'features',
    ],
  );
  final val = SubscriptionPlanModel(
    code: $checkedConvert(
      'code',
      (v) => $enumDecode(_$PlanCodeModelEnumMap, v),
    ),
    name: $checkedConvert('name', (v) => v as String),
    amountCents: $checkedConvert('amountCents', (v) => (v as num).toInt()),
    currency: $checkedConvert('currency', (v) => v as String),
    interval: $checkedConvert(
      'interval',
      (v) => $enumDecode(_$PlanIntervalModelEnumMap, v),
    ),
    intervalCount: $checkedConvert('intervalCount', (v) => (v as num).toInt()),
    monthlyEquivalentCents: $checkedConvert(
      'monthlyEquivalentCents',
      (v) => (v as num).toInt(),
    ),
    annualSavingsPercent: $checkedConvert(
      'annualSavingsPercent',
      (v) => (v as num).toInt(),
    ),
    checkoutAvailable: $checkedConvert('checkoutAvailable', (v) => v as bool),
    features: $checkedConvert(
      'features',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
  );
  return val;
});

const _$PlanCodeModelEnumMap = {
  PlanCodeModel.free: 'FREE',
  PlanCodeModel.proMonthly: 'PRO_MONTHLY',
  PlanCodeModel.proAnnual: 'PRO_ANNUAL',
};

const _$PlanIntervalModelEnumMap = {
  PlanIntervalModel.none: 'NONE',
  PlanIntervalModel.month: 'MONTH',
  PlanIntervalModel.year: 'YEAR',
};
