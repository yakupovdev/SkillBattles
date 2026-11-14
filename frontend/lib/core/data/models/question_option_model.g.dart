// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_option_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuestionOptionModel _$QuestionOptionModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('QuestionOptionModel', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'text']);
      final val = QuestionOptionModel(
        id: $checkedConvert('id', (v) => v as String),
        text: $checkedConvert('text', (v) => v as String),
      );
      return val;
    });
