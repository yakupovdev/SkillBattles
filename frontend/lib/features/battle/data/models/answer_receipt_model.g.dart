// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'answer_receipt_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnswerReceiptModel _$AnswerReceiptModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AnswerReceiptModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'battleId',
          'roundId',
          'submissionId',
          'accepted',
          'acceptedAt',
        ],
      );
      final val = AnswerReceiptModel(
        battleId: $checkedConvert('battleId', (v) => v as String),
        roundId: $checkedConvert('roundId', (v) => v as String),
        submissionId: $checkedConvert('submissionId', (v) => v as String),
        accepted: $checkedConvert('accepted', (v) => v as bool),
        acceptedAt: $checkedConvert(
          'acceptedAt',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    });
