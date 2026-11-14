// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_entry_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QueueEntryModel _$QueueEntryModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('QueueEntryModel', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'id',
      'disciplineCode',
      'format',
      'status',
      'createdAt',
      'expiresAt',
      'ratingWindow',
      'battleId',
      'version',
      'error',
    ],
  );
  final val = QueueEntryModel(
    id: $checkedConvert('id', (v) => v as String),
    disciplineCode: $checkedConvert('disciplineCode', (v) => v as String),
    format: $checkedConvert(
      'format',
      (v) => $enumDecode(_$BattleFormatModelEnumMap, v),
    ),
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$QueueStatusModelEnumMap, v),
    ),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
    expiresAt: $checkedConvert('expiresAt', (v) => DateTime.parse(v as String)),
    ratingWindow: $checkedConvert('ratingWindow', (v) => (v as num).toInt()),
    battleId: $checkedConvert('battleId', (v) => v as String?),
    version: $checkedConvert('version', (v) => (v as num).toInt()),
    error: $checkedConvert(
      'error',
      (v) => v == null
          ? null
          : ErrorResponseModel.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

const _$BattleFormatModelEnumMap = {BattleFormatModel.standard: 'STANDARD'};

const _$QueueStatusModelEnumMap = {
  QueueStatusModel.searching: 'SEARCHING',
  QueueStatusModel.matched: 'MATCHED',
  QueueStatusModel.cancelled: 'CANCELLED',
  QueueStatusModel.expired: 'EXPIRED',
};
