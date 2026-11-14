import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/battle_mode.dart';
import 'package:skill_battles/core/domain/entity/battle_result_entity.dart';
import 'package:skill_battles/core/domain/entity/entitlements_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_phase.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_player_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_round_entity.dart';

/// Personalised battle state for [myUserId].
final class BattleSnapshotEntity extends Equatable {
  const BattleSnapshotEntity({
    required this.id,
    required this.disciplineCode,
    required this.mode,
    required this.seasonId,
    required this.phase,
    required this.version,
    required this.serverTime,
    required this.receivedAt,
    required this.questionCount,
    required this.overtimePlayed,
    required this.readyDeadline,
    required this.countdownEndsAt,
    required this.nextRoundStartsAt,
    required this.players,
    required this.round,
    required this.result,
    required this.entitlements,
    required this.myUserId,
  });

  final String id;
  final String disciplineCode;
  final BattleMode mode;
  final String? seasonId;
  final BattlePhase phase;

  /// Monotonic per battle; compare only with this battle's versions.
  final int version;
  final DateTime serverTime;

  /// Local instant the snapshot arrived, for the server clock offset.
  final DateTime receivedAt;

  /// Regular rounds; overtime comes on top.
  final int questionCount;
  final bool overtimePlayed;
  final DateTime? readyDeadline;
  final DateTime? countdownEndsAt;
  final DateTime? nextRoundStartsAt;
  final List<BattlePlayerEntity> players;
  final BattleRoundEntity? round;
  final BattleResultEntity? result;
  final EntitlementsEntity entitlements;
  final String myUserId;

  /// Server time minus local time when the snapshot arrived.
  Duration get clockOffset => serverTime.difference(receivedAt);

  BattlePlayerEntity get me => players.firstWhere(
    (BattlePlayerEntity p) => p.id == myUserId,
    orElse: () => players.first,
  );

  BattlePlayerEntity get opponent => players.firstWhere(
    (BattlePlayerEntity p) => p.id != me.id,
    orElse: () => players.last,
  );

  /// The next server-side transition the client expects; used only to
  /// re-read the snapshot if no event arrives.
  DateTime? get nextTransitionAt => switch (phase) {
    BattlePhase.waitingReady => readyDeadline,
    BattlePhase.countdown => countdownEndsAt,
    BattlePhase.question => round?.deadline,
    BattlePhase.reveal => nextRoundStartsAt,
    BattlePhase.finished || BattlePhase.cancelled => null,
  };

  @override
  List<Object?> get props => <Object?>[
    id,
    disciplineCode,
    mode,
    seasonId,
    phase,
    version,
    serverTime,
    receivedAt,
    questionCount,
    overtimePlayed,
    readyDeadline,
    countdownEndsAt,
    nextRoundStartsAt,
    players,
    round,
    result,
    entitlements,
    myUserId,
  ];
}
