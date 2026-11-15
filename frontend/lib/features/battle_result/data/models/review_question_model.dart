import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/difficulty_model.dart';
import 'package:skill_battles/core/data/models/question_option_model.dart';
import 'package:skill_battles/core/domain/entity/question_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/review_question_entity.dart';

part 'review_question_model.g.dart';

/// Question of a review; correct option and explanation are null for Free.
@JsonSerializable(checked: true, createToJson: false)
final class ReviewQuestionModel {
  const ReviewQuestionModel({
    required this.id,
    required this.topicCode,
    required this.topicName,
    required this.difficulty,
    required this.prompt,
    required this.options,
    required this.correctOptionId,
    required this.explanation,
    this.imageUrl,
  });

  factory ReviewQuestionModel.fromJson(Map<String, dynamic> json) =>
      _$ReviewQuestionModelFromJson(json);

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

  @JsonKey(required: true)
  final String? correctOptionId;

  @JsonKey(required: true)
  final String? explanation;

  /// Origin-relative illustration URL, `null` when absent. Not `required`:
  /// older payloads omit the key, which means no illustration.
  final String? imageUrl;

  ReviewQuestionEntity toEntity() => ReviewQuestionEntity(
    question: QuestionEntity(
      id: id,
      topicCode: topicCode,
      topicName: topicName,
      difficulty: difficulty.toEntity(),
      prompt: prompt,
      options: options
          .map((QuestionOptionModel option) => option.toEntity())
          .toList(growable: false),
      imageUrl: imageUrl,
    ),
    correctOptionId: correctOptionId,
    explanation: explanation,
  );
}
