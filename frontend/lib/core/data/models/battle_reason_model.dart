import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/domain/entity/battle_reason.dart';

/// Why the battle ended.
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum BattleReasonModel {
  normal,
  overtimeWin,
  surrender,
  disconnect,
  readyTimeout,
  bothDisconnected,
  serverInterruption,
  quotaExhausted;

  BattleReason toEntity() => switch (this) {
    BattleReasonModel.normal => BattleReason.normal,
    BattleReasonModel.overtimeWin => BattleReason.overtimeWin,
    BattleReasonModel.surrender => BattleReason.surrender,
    BattleReasonModel.disconnect => BattleReason.disconnect,
    BattleReasonModel.readyTimeout => BattleReason.readyTimeout,
    BattleReasonModel.bothDisconnected => BattleReason.bothDisconnected,
    BattleReasonModel.serverInterruption => BattleReason.serverInterruption,
    BattleReasonModel.quotaExhausted => BattleReason.quotaExhausted,
  };
}
