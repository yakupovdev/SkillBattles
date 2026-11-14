// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'season_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SeasonModel _$SeasonModelFromJson(Map<String, dynamic> json) => $checkedCreate(
  'SeasonModel',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['id', 'name', 'startsAt', 'endsAt', 'timezone'],
    );
    final val = SeasonModel(
      id: $checkedConvert('id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      startsAt: $checkedConvert('startsAt', (v) => DateTime.parse(v as String)),
      endsAt: $checkedConvert('endsAt', (v) => DateTime.parse(v as String)),
      timezone: $checkedConvert('timezone', (v) => v as String),
    );
    return val;
  },
);
