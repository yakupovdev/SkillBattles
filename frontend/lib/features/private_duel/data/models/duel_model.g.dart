// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'duel_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DuelModel _$DuelModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DuelModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'code',
          'disciplineCode',
          'format',
          'status',
          'host',
          'guest',
          'expiresAt',
          'battleId',
          'version',
        ],
      );
      final val = DuelModel(
        id: $checkedConvert('id', (v) => v as String),
        code: $checkedConvert('code', (v) => v as String),
        disciplineCode: $checkedConvert('disciplineCode', (v) => v as String),
        format: $checkedConvert(
          'format',
          (v) => $enumDecode(_$BattleFormatModelEnumMap, v),
        ),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$DuelStatusModelEnumMap, v),
        ),
        host: $checkedConvert(
          'host',
          (v) => PublicPlayerModel.fromJson(v as Map<String, dynamic>),
        ),
        guest: $checkedConvert(
          'guest',
          (v) => v == null
              ? null
              : PublicPlayerModel.fromJson(v as Map<String, dynamic>),
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

const _$BattleFormatModelEnumMap = {BattleFormatModel.standard: 'STANDARD'};

const _$DuelStatusModelEnumMap = {
  DuelStatusModel.waiting: 'WAITING',
  DuelStatusModel.matched: 'MATCHED',
  DuelStatusModel.cancelled: 'CANCELLED',
  DuelStatusModel.expired: 'EXPIRED',
};
