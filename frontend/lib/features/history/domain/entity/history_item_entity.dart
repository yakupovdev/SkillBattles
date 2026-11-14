import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/battle_mode.dart';
import 'package:skill_battles/core/domain/entity/battle_outcome.dart';
import 'package:skill_battles/core/domain/entity/battle_reason.dart';
import 'package:skill_battles/core/domain/entity/public_player_entity.dart';

/// One terminal match of the own history.
final class HistoryItemEntity extends Equatable {
  const HistoryItemEntity({
    required this.battleId,
    required this.disciplineCode,
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

  final String battleId;
  final String disciplineCode;
  final BattleMode mode;
  final BattleOutcome outcome;
  final BattleReason reason;
  final PublicPlayerEntity opponent;
  final int myScore;
  final int opponentScore;
  final int ratingDelta;
  final String? seasonId;
  final bool overtimePlayed;
  final DateTime createdAt;
  final DateTime finishedAt;

  @override
  List<Object?> get props => <Object?>[
    battleId,
    disciplineCode,
    mode,
    outcome,
    reason,
    opponent,
    myScore,
    opponentScore,
    ratingDelta,
    seasonId,
    overtimePlayed,
    createdAt,
    finishedAt,
  ];
}
