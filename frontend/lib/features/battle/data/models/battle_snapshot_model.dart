import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/battle_format_model.dart';
import 'package:skill_battles/core/data/models/battle_result_model.dart';
import 'package:skill_battles/core/data/models/competition_mode_model.dart';
import 'package:skill_battles/core/data/models/entitlements_model.dart';
import 'package:skill_battles/features/battle/data/models/battle_phase_model.dart';
import 'package:skill_battles/features/battle/data/models/battle_player_model.dart';
import 'package:skill_battles/features/battle/data/models/battle_round_model.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_snapshot_entity.dart';

part 'battle_snapshot_model.g.dart';

/// Personalised battle snapshot.
@JsonSerializable(checked: true, createToJson: false)
final class BattleSnapshotModel {
  const BattleSnapshotModel({
    required this.id,
    required this.disciplineCode,
    required this.format,
    required this.mode,
    required this.rulesVersion,
    required this.seasonId,
    required this.phase,
    required this.version,
    required this.serverTime,
    required this.questionCount,
    required this.overtimePlayed,
    required this.readyDeadline,
    required this.countdownEndsAt,
    required this.nextRoundStartsAt,
    required this.players,
    required this.round,
    required this.result,
    required this.entitlements,
  });

  factory BattleSnapshotModel.fromJson(Map<String, dynamic> json) =>
      _$BattleSnapshotModelFromJson(json);

  @JsonKey(required: true)
  final String id;

  @JsonKey(required: true)
  final String disciplineCode;

  @JsonKey(required: true)
  final BattleFormatModel format;

  @JsonKey(required: true)
  final CompetitionModeModel mode;

  @JsonKey(required: true)
  final String rulesVersion;

  @JsonKey(required: true)
  final String? seasonId;

  @JsonKey(required: true)
  final BattlePhaseModel phase;

  @JsonKey(required: true)
  final int version;

  @JsonKey(required: true)
  final DateTime serverTime;

  @JsonKey(required: true)
  final int questionCount;

  @JsonKey(required: true)
  final bool overtimePlayed;

  @JsonKey(required: true)
  final DateTime? readyDeadline;

  @JsonKey(required: true)
  final DateTime? countdownEndsAt;

  @JsonKey(required: true)
  final DateTime? nextRoundStartsAt;

  @JsonKey(required: true)
  final List<BattlePlayerModel> players;

  @JsonKey(required: true)
  final BattleRoundModel? round;

  @JsonKey(required: true)
  final BattleResultModel? result;

  @JsonKey(required: true)
  final EntitlementsModel entitlements;

  BattleSnapshotEntity toEntity({
    required String myUserId,
    required DateTime receivedAt,
  }) => BattleSnapshotEntity(
    id: id,
    disciplineCode: disciplineCode,
    mode: mode.toEntity(),
    seasonId: seasonId,
    phase: phase.toEntity(),
    version: version,
    serverTime: serverTime,
    receivedAt: receivedAt,
    questionCount: questionCount,
    overtimePlayed: overtimePlayed,
    readyDeadline: readyDeadline,
    countdownEndsAt: countdownEndsAt,
    nextRoundStartsAt: nextRoundStartsAt,
    players: players
        .map((BattlePlayerModel player) => player.toEntity())
        .toList(growable: false),
    round: round?.toEntity(),
    result: result?.toEntity(myUserId: myUserId),
    entitlements: entitlements.toEntity(),
    myUserId: myUserId,
  );
}
