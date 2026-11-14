import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/battle/domain/entity/battle_phase.dart';

/// Phase of a battle.
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum BattlePhaseModel {
  waitingReady,
  countdown,
  question,
  reveal,
  finished,
  cancelled;

  BattlePhase toEntity() => switch (this) {
    BattlePhaseModel.waitingReady => BattlePhase.waitingReady,
    BattlePhaseModel.countdown => BattlePhase.countdown,
    BattlePhaseModel.question => BattlePhase.question,
    BattlePhaseModel.reveal => BattlePhase.reveal,
    BattlePhaseModel.finished => BattlePhase.finished,
    BattlePhaseModel.cancelled => BattlePhase.cancelled,
  };
}
