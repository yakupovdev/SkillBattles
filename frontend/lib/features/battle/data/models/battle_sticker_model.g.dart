// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'battle_sticker_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BattleStickerModel _$BattleStickerModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BattleStickerModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'battleId',
          'submissionId',
          'senderUserId',
          'stickerId',
          'sentAt',
        ],
      );
      final val = BattleStickerModel(
        battleId: $checkedConvert('battleId', (v) => v as String),
        submissionId: $checkedConvert('submissionId', (v) => v as String),
        senderUserId: $checkedConvert('senderUserId', (v) => v as String),
        stickerId: $checkedConvert('stickerId', (v) => v as String),
        sentAt: $checkedConvert('sentAt', (v) => DateTime.parse(v as String)),
      );
      return val;
    });
