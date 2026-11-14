import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/difficulty_model.dart';
import 'package:skill_battles/core/data/models/question_option_model.dart';
import 'package:skill_battles/core/domain/entity/question_entity.dart';

part 'question_model.g.dart';

/// Question without the correct answer.
@JsonSerializable(checked: true, createToJson: false)
final class QuestionModel {
  const QuestionModel({
    required this.id,
    required this.topicCode,
    required this.topicName,
    required this.difficulty,
    required this.prompt,
    required this.options,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) =>
      _$QuestionModelFromJson(json);

  @JsonKey(required: true)
  final String id;

  @JsonKey(required: true)
  final String topicCode;

  @JsonKey(required: true)
  final String topicName;

  @JsonKey(required: true)
  final DifficultyModel difficulty;

  @JsonKey(required: true)
  final String prompt;

  @JsonKey(required: true)
  final List<QuestionOptionModel> options;

  QuestionEntity toEntity() => QuestionEntity(
    id: id,
    topicCode: topicCode,
    topicName: topicName,
    difficulty: difficulty.toEntity(),
    prompt: prompt,
    options: options
        .map((QuestionOptionModel option) => option.toEntity())
        .toList(growable: false),
  );
}
