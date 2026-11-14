// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_question_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewQuestionModel _$ReviewQuestionModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ReviewQuestionModel', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'id',
      'topicCode',
      'topicName',
      'difficulty',
      'prompt',
      'options',
      'correctOptionId',
      'explanation',
    ],
  );
  final val = ReviewQuestionModel(
    id: $checkedConvert('id', (v) => v as String),
    topicCode: $checkedConvert('topicCode', (v) => v as String),
    topicName: $checkedConvert('topicName', (v) => v as String),
    difficulty: $checkedConvert(
      'difficulty',
      (v) => $enumDecode(_$DifficultyModelEnumMap, v),
    ),
    prompt: $checkedConvert('prompt', (v) => v as String),
    options: $checkedConvert(
      'options',
      (v) => (v as List<dynamic>)
          .map((e) => QuestionOptionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    correctOptionId: $checkedConvert('correctOptionId', (v) => v as String?),
    explanation: $checkedConvert('explanation', (v) => v as String?),
  );
  return val;
});

const _$DifficultyModelEnumMap = {
  DifficultyModel.easy: 'EASY',
  DifficultyModel.medium: 'MEDIUM',
  DifficultyModel.hard: 'HARD',
};
