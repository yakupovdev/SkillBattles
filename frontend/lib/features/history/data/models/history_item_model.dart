import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/battle_format_model.dart';
import 'package:skill_battles/core/data/models/battle_outcome_model.dart';
import 'package:skill_battles/core/data/models/battle_reason_model.dart';
import 'package:skill_battles/core/data/models/competition_mode_model.dart';
import 'package:skill_battles/core/data/models/public_player_model.dart';
import 'package:skill_battles/features/history/domain/entity/history_item_entity.dart';

part 'history_item_model.g.dart';

/// One match of the own history.
@JsonSerializable(checked: true, createToJson: false)
final class HistoryItemModel {
  const HistoryItemModel({
    required this.battleId,
    required this.disciplineCode,
    required this.format,
    required this.mode,
    required this.outcome,
    required this.reason,
    required this.opponent,
    required this.myScore,
    required this.opponentScore,
    required this.ratingDelta,
    required this.seasonId,
    required this.overtimePlayed,
    required this.createdAt,
    required this.finishedAt,
  });

  factory HistoryItemModel.fromJson(Map<String, dynamic> json) =>
      _$HistoryItemModelFromJson(json);

  @JsonKey(required: true)
  final String battleId;

  @JsonKey(required: true)
  final String disciplineCode;

  @JsonKey(required: true)
  final BattleFormatModel format;

  @JsonKey(required: true)
  final CompetitionModeModel mode;

  @JsonKey(required: true)
  final BattleOutcomeModel outcome;

  @JsonKey(required: true)
  final BattleReasonModel reason;

  @JsonKey(required: true)
  final PublicPlayerModel opponent;

  @JsonKey(required: true)
  final int myScore;

  @JsonKey(required: true)
  final int opponentScore;

  @JsonKey(required: true)
  final int ratingDelta;

  @JsonKey(required: true)
  final String? seasonId;

  @JsonKey(required: true)
  final bool overtimePlayed;

  @JsonKey(required: true)
  final DateTime createdAt;

  @JsonKey(required: true)
  final DateTime finishedAt;

  HistoryItemEntity toEntity() => HistoryItemEntity(
    battleId: battleId,
    disciplineCode: disciplineCode,
    mode: mode.toEntity(),
    outcome: outcome.toEntity(),
    reason: reason.toEntity(),
    opponent: opponent.toEntity(),
    myScore: myScore,
    opponentScore: opponentScore,
    ratingDelta: ratingDelta,
    seasonId: seasonId,
    overtimePlayed: overtimePlayed,
    createdAt: createdAt,
    finishedAt: finishedAt,
  );
}
