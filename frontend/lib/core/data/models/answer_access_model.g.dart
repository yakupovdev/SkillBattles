// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'answer_access_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnswerAccessModel _$AnswerAccessModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AnswerAccessModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'canViewCorrectAnswer',
          'canViewExplanation',
          'entitlementVersion',
        ],
      );
      final val = AnswerAccessModel(
        canViewCorrectAnswer: $checkedConvert(
          'canViewCorrectAnswer',
          (v) => v as bool,
        ),
        canViewExplanation: $checkedConvert(
          'canViewExplanation',
          (v) => v as bool,
        ),
        entitlementVersion: $checkedConvert(
          'entitlementVersion',
          (v) => (v as num).toInt(),
        ),
      );
      return val;
    });
