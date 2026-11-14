import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/question_model.dart';
import 'package:skill_battles/features/battle/data/models/round_reveal_model.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_round_entity.dart';

part 'battle_round_model.g.dart';

/// Current round of a battle.
@JsonSerializable(checked: true, createToJson: false)
final class BattleRoundModel {
  const BattleRoundModel({
    required this.id,
    required this.number,
    required this.isOvertimeRound,
    required this.startedAt,
    required this.deadline,
    required this.limitSeconds,
    required this.question,
    required this.mySelectedOptionId,
    required this.reveal,
  });

  factory BattleRoundModel.fromJson(Map<String, dynamic> json) =>
      _$BattleRoundModelFromJson(json);

  @JsonKey(required: true)
  final String id;

  @JsonKey(required: true)
  final int number;

  @JsonKey(required: true)
  final bool isOvertimeRound;

  @JsonKey(required: true)
  final DateTime startedAt;

  @JsonKey(required: true)
  final DateTime deadline;

  @JsonKey(required: true)
  final int limitSeconds;

  @JsonKey(required: true)
  final QuestionModel question;

  @JsonKey(required: true)
  final String? mySelectedOptionId;

  @JsonKey(required: true)
  final RoundRevealModel? reveal;

  BattleRoundEntity toEntity() => BattleRoundEntity(
    id: id,
    number: number,
    isOvertime: isOvertimeRound,
    startedAt: startedAt,
    deadline: deadline,
    limitSeconds: limitSeconds,
    question: question.toEntity(),
    mySelectedOptionId: mySelectedOptionId,
    reveal: reveal?.toEntity(),
  );
}
