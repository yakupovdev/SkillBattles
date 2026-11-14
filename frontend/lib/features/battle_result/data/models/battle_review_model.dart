import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/answer_access_model.dart';
import 'package:skill_battles/core/data/models/competition_mode_model.dart';
import 'package:skill_battles/features/battle_result/data/models/review_round_model.dart';
import 'package:skill_battles/features/battle_result/domain/entity/battle_review_entity.dart';

part 'battle_review_model.g.dart';

/// Review of a terminal battle.
@JsonSerializable(checked: true, createToJson: false)
final class BattleReviewModel {
  const BattleReviewModel({
    required this.battleId,
    required this.disciplineCode,
    required this.mode,
    required this.rulesVersion,
    required this.mistakesOnly,
    required this.answerAccess,
    required this.rounds,
  });

  factory BattleReviewModel.fromJson(Map<String, dynamic> json) =>
      _$BattleReviewModelFromJson(json);

  @JsonKey(required: true)
  final String battleId;

  @JsonKey(required: true)
  final String disciplineCode;

  @JsonKey(required: true)
  final CompetitionModeModel mode;

  @JsonKey(required: true)
  final String rulesVersion;

  @JsonKey(required: true)
  final bool mistakesOnly;

  @JsonKey(required: true)
  final AnswerAccessModel answerAccess;

  @JsonKey(required: true)
  final List<ReviewRoundModel> rounds;

  BattleReviewEntity toEntity({required String myUserId}) => BattleReviewEntity(
    battleId: battleId,
    disciplineCode: disciplineCode,
    mode: mode.toEntity(),
    mistakesOnly: mistakesOnly,
    answerAccess: answerAccess.toEntity(),
    rounds: rounds
        .map((ReviewRoundModel round) => round.toEntity())
        .toList(growable: false),
    myUserId: myUserId,
  );
}
