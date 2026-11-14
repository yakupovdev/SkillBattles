// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rematch_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RematchModel _$RematchModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RematchModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'sourceBattleId',
          'status',
          'requestedBy',
          'expiresAt',
          'battleId',
          'version',
        ],
      );
      final val = RematchModel(
        sourceBattleId: $checkedConvert('sourceBattleId', (v) => v as String),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$RematchStatusModelEnumMap, v),
        ),
        requestedBy: $checkedConvert(
          'requestedBy',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        expiresAt: $checkedConvert(
          'expiresAt',
          (v) => DateTime.parse(v as String),
        ),
        battleId: $checkedConvert('battleId', (v) => v as String?),
        version: $checkedConvert('version', (v) => (v as num).toInt()),
      );
      return val;
    });

const _$RematchStatusModelEnumMap = {
  RematchStatusModel.waiting: 'WAITING',
  RematchStatusModel.matched: 'MATCHED',
  RematchStatusModel.expired: 'EXPIRED',
  RematchStatusModel.cancelled: 'CANCELLED',
};
