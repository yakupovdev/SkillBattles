import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/battle_mode.dart';
import 'package:skill_battles/core/domain/entity/battle_outcome.dart';
import 'package:skill_battles/core/domain/entity/battle_reason.dart';
import 'package:skill_battles/core/domain/entity/battle_status.dart';
import 'package:skill_battles/core/domain/entity/result_player_entity.dart';

/// Immutable outcome of a terminal battle, seen by [myUserId].
final class BattleResultEntity extends Equatable {
  const BattleResultEntity({
    required this.battleId,
    required this.disciplineCode,
    required this.mode,
    required this.seasonId,
    required this.status,
    required this.reason,
    required this.winnerUserId,
    required this.myOutcome,
    required this.finishedAt,
    required this.overtimePlayed,
    required this.players,
    required this.myUserId,
  });

  final String battleId;
  final String disciplineCode;
  final BattleMode mode;

  /// Frozen ranked season; `null` for private.
  final String? seasonId;
  final BattleStatus status;
  final BattleReason reason;
  final String? winnerUserId;
  final BattleOutcome myOutcome;
  final DateTime finishedAt;
  final bool overtimePlayed;
  final List<ResultPlayerEntity> players;
  final String myUserId;

  ResultPlayerEntity get me => players.firstWhere(
    (ResultPlayerEntity p) => p.id == myUserId,
    orElse: () => players.first,
  );

  ResultPlayerEntity get opponent => players.firstWhere(
    (ResultPlayerEntity p) => p.id != me.id,
    orElse: () => players.last,
  );

  /// The winner by forfeit can have fewer points than the loser.
  bool get isForfeit =>
      reason == BattleReason.surrender || reason == BattleReason.disconnect;

  @override
  List<Object?> get props => <Object?>[
    battleId,
    disciplineCode,
    mode,
    seasonId,
    status,
    reason,
    winnerUserId,
    myOutcome,
    finishedAt,
    overtimePlayed,
    players,
    myUserId,
  ];
}
