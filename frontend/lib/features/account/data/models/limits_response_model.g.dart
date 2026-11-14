// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'limits_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LimitsResponseModel _$LimitsResponseModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LimitsResponseModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'planCode',
          'timezone',
          'date',
          'freeRankedLimit',
          'rankedStartedToday',
          'freeRankedRemaining',
          'resetsAt',
          'canStartRanked',
          'entitlements',
        ],
      );
      final val = LimitsResponseModel(
        planCode: $checkedConvert(
          'planCode',
          (v) => $enumDecode(_$PlanCodeModelEnumMap, v),
        ),
        timezone: $checkedConvert('timezone', (v) => v as String),
        date: $checkedConvert('date', (v) => DateTime.parse(v as String)),
        freeRankedLimit: $checkedConvert(
          'freeRankedLimit',
          (v) => (v as num).toInt(),
        ),
        rankedStartedToday: $checkedConvert(
          'rankedStartedToday',
          (v) => (v as num).toInt(),
        ),
        freeRankedRemaining: $checkedConvert(
          'freeRankedRemaining',
          (v) => (v as num?)?.toInt(),
        ),
        resetsAt: $checkedConvert(
          'resetsAt',
          (v) => DateTime.parse(v as String),
        ),
        canStartRanked: $checkedConvert('canStartRanked', (v) => v as bool),
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
