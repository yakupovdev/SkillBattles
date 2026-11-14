// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StatisticsResponseModel _$StatisticsResponseModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('StatisticsResponseModel', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['entitlements', 'streaks', 'disciplines'],
  );
  final val = StatisticsResponseModel(
    entitlements: $checkedConvert(
      'entitlements',
      (v) => EntitlementsModel.fromJson(v as Map<String, dynamic>),
    ),
    streaks: $checkedConvert(
      'streaks',
      (v) => StreaksModel.fromJson(v as Map<String, dynamic>),
    ),
    disciplines: $checkedConvert(
      'disciplines',
      (v) => (v as List<dynamic>)
          .map((e) => DisciplineStatsModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});
