import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/answer_access_model.dart';
import 'package:skill_battles/core/data/models/round_answer_model.dart';
import 'package:skill_battles/features/battle/domain/entity/round_reveal_entity.dart';

part 'round_reveal_model.g.dart';

/// Reveal of a finished round.
@JsonSerializable(checked: true, createToJson: false)
final class RoundRevealModel {
  const RoundRevealModel({
    required this.correctOptionId,
    required this.answers,
    required this.answerAccess,
  });

  factory RoundRevealModel.fromJson(Map<String, dynamic> json) =>
      _$RoundRevealModelFromJson(json);

  @JsonKey(required: true)
  final String? correctOptionId;

  @JsonKey(required: true)
  final List<RoundAnswerModel> answers;

  @JsonKey(required: true)
  final AnswerAccessModel answerAccess;

  RoundRevealEntity toEntity() => RoundRevealEntity(
    correctOptionId: correctOptionId,
    answers: answers
        .map((RoundAnswerModel answer) => answer.toEntity())
        .toList(growable: false),
    answerAccess: answerAccess.toEntity(),
  );
}
