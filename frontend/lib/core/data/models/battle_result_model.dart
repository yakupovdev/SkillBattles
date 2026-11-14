import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/battle_format_model.dart';
import 'package:skill_battles/core/data/models/battle_outcome_model.dart';
import 'package:skill_battles/core/data/models/battle_reason_model.dart';
import 'package:skill_battles/core/data/models/battle_status_model.dart';
import 'package:skill_battles/core/data/models/competition_mode_model.dart';
import 'package:skill_battles/core/data/models/result_player_model.dart';
import 'package:skill_battles/core/domain/entity/battle_result_entity.dart';

part 'battle_result_model.g.dart';

/// Saved outcome of a terminal battle.
@JsonSerializable(checked: true, createToJson: false)
final class BattleResultModel {
  const BattleResultModel({
    required this.battleId,
    required this.disciplineCode,
    required this.format,
    required this.mode,
    required this.seasonId,
    required this.rulesVersion,
    required this.status,
    required this.reason,
    required this.winnerUserId,
    required this.myOutcome,
    required this.finishedAt,
    required this.overtimePlayed,
    required this.players,
  });

  factory BattleResultModel.fromJson(Map<String, dynamic> json) =>
      _$BattleResultModelFromJson(json);

  @JsonKey(required: true)
  final String battleId;

  @JsonKey(required: true)
  final String disciplineCode;

  @JsonKey(required: true)
  final BattleFormatModel format;

  @JsonKey(required: true)
  final CompetitionModeModel mode;

  @JsonKey(required: true)
  final String? seasonId;

  @JsonKey(required: true)
  final String rulesVersion;

  @JsonKey(required: true)
  final BattleStatusModel status;

  @JsonKey(required: true)
  final BattleReasonModel reason;

  @JsonKey(required: true)
  final String? winnerUserId;

  @JsonKey(required: true)
  final BattleOutcomeModel myOutcome;

  @JsonKey(required: true)
  final DateTime finishedAt;

  @JsonKey(required: true)
  final bool overtimePlayed;

  @JsonKey(required: true)
  final List<ResultPlayerModel> players;

  BattleResultEntity toEntity({required String myUserId}) => BattleResultEntity(
    battleId: battleId,
    disciplineCode: disciplineCode,
    mode: mode.toEntity(),
    seasonId: seasonId,
    status: status.toEntity(),
    reason: reason.toEntity(),
    winnerUserId: winnerUserId,
    myOutcome: myOutcome.toEntity(),
    finishedAt: finishedAt,
    overtimePlayed: overtimePlayed,
    players: players
        .map((ResultPlayerModel player) => player.toEntity())
        .toList(growable: false),
    myUserId: myUserId,
  );
}
