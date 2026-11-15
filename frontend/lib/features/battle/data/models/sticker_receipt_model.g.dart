// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sticker_receipt_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StickerReceiptModel _$StickerReceiptModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StickerReceiptModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'battleId',
          'submissionId',
          'senderUserId',
          'stickerId',
          'sentAt',
          'nextAllowedAt',
        ],
      );
      final val = StickerReceiptModel(
        battleId: $checkedConvert('battleId', (v) => v as String),
        submissionId: $checkedConvert('submissionId', (v) => v as String),
        senderUserId: $checkedConvert('senderUserId', (v) => v as String),
        stickerId: $checkedConvert('stickerId', (v) => v as String),
        sentAt: $checkedConvert('sentAt', (v) => DateTime.parse(v as String)),
        nextAllowedAt: $checkedConvert(
          'nextAllowedAt',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    });
