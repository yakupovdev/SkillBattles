import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/domain/entity/round_answer_entity.dart';

part 'round_answer_model.g.dart';

/// Revealed answer of one player; selection of the opponent is null for Free.
@JsonSerializable(checked: true, createToJson: false)
final class RoundAnswerModel {
  const RoundAnswerModel({
    required this.userId,
    required this.selectedOptionId,
    required this.correct,
    required this.elapsedMs,
    required this.basePoints,
    required this.speedBonus,
    required this.streakBonus,
    required this.tieBreakPoints,
    required this.points,
    required this.timedOut,
  });

  factory RoundAnswerModel.fromJson(Map<String, dynamic> json) =>
      _$RoundAnswerModelFromJson(json);

  @JsonKey(required: true)
  final String userId;

  @JsonKey(required: true)
  final String? selectedOptionId;

  @JsonKey(required: true)
  final bool correct;

  @JsonKey(required: true)
  final int? elapsedMs;

  @JsonKey(required: true)
  final int basePoints;

  @JsonKey(required: true)
  final int speedBonus;

  @JsonKey(required: true)
  final int streakBonus;

  @JsonKey(required: true)
  final int tieBreakPoints;

  @JsonKey(required: true)
  final int points;

  @JsonKey(required: true)
  final bool timedOut;

  RoundAnswerEntity toEntity() {
    final int? ms = elapsedMs;
    return RoundAnswerEntity(
      userId: userId,
      selectedOptionId: selectedOptionId,
      correct: correct,
      elapsed: ms == null ? null : Duration(milliseconds: ms),
      basePoints: basePoints,
      speedBonus: speedBonus,
      streakBonus: streakBonus,
      tieBreakPoints: tieBreakPoints,
      points: points,
      timedOut: timedOut,
    );
  }
}
