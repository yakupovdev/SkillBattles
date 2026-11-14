// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportResponseModel _$ReportResponseModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ReportResponseModel', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'battleId', 'roundId', 'status', 'createdAt'],
  );
  final val = ReportResponseModel(
    id: $checkedConvert('id', (v) => v as String),
    battleId: $checkedConvert('battleId', (v) => v as String),
    roundId: $checkedConvert('roundId', (v) => v as String),
    status: $checkedConvert('status', (v) => v as String),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
  );
  return val;
});
