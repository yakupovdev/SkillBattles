import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/round_answer_model.dart';
import 'package:skill_battles/features/battle_result/data/models/review_question_model.dart';
import 'package:skill_battles/features/battle_result/domain/entity/review_round_entity.dart';

part 'review_round_model.g.dart';

/// One started round of a review.
@JsonSerializable(checked: true, createToJson: false)
final class ReviewRoundModel {
  const ReviewRoundModel({
    required this.roundId,
    required this.number,
    required this.isOvertimeRound,
    required this.completed,
    required this.question,
    required this.answers,
  });

  factory ReviewRoundModel.fromJson(Map<String, dynamic> json) =>
      _$ReviewRoundModelFromJson(json);

  @JsonKey(required: true)
  final String roundId;

  @JsonKey(required: true)
  final int number;

  @JsonKey(required: true)
  final bool isOvertimeRound;

  @JsonKey(required: true)
  final bool completed;

  @JsonKey(required: true)
  final ReviewQuestionModel question;

  @JsonKey(required: true)
  final List<RoundAnswerModel> answers;

  ReviewRoundEntity toEntity() => ReviewRoundEntity(
    roundId: roundId,
    number: number,
    isOvertime: isOvertimeRound,
    completed: completed,
    question: question.toEntity(),
    answers: answers
        .map((RoundAnswerModel answer) => answer.toEntity())
        .toList(growable: false),
  );
}
