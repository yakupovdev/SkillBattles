// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streaks_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StreaksModel _$StreaksModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('StreaksModel', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'timezone',
      'dailyCurrent',
      'dailyBest',
      'lastQualifiedDate',
      'weeklyCurrent',
      'weeklyBest',
      'currentWeekStart',
      'currentWeekActiveDays',
      'currentWeekTarget',
    ],
  );
  final val = StreaksModel(
    timezone: $checkedConvert('timezone', (v) => v as String),
    dailyCurrent: $checkedConvert('dailyCurrent', (v) => (v as num).toInt()),
    dailyBest: $checkedConvert('dailyBest', (v) => (v as num).toInt()),
    lastQualifiedDate: $checkedConvert(
      'lastQualifiedDate',
      (v) => v == null ? null : DateTime.parse(v as String),
    ),
    weeklyCurrent: $checkedConvert('weeklyCurrent', (v) => (v as num).toInt()),
    weeklyBest: $checkedConvert('weeklyBest', (v) => (v as num).toInt()),
    currentWeekStart: $checkedConvert(
      'currentWeekStart',
      (v) => DateTime.parse(v as String),
    ),
    currentWeekActiveDays: $checkedConvert(
      'currentWeekActiveDays',
      (v) => (v as num).toInt(),
    ),
    currentWeekTarget: $checkedConvert(
      'currentWeekTarget',
      (v) => (v as num).toInt(),
    ),
  );
  return val;
});
