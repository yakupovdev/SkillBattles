import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/domain/entity/battle_outcome.dart';

/// Outcome from the caller perspective.
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum BattleOutcomeModel {
  win,
  loss,
  draw,
  cancelled;

  BattleOutcome toEntity() => switch (this) {
    BattleOutcomeModel.win => BattleOutcome.win,
    BattleOutcomeModel.loss => BattleOutcome.loss,
    BattleOutcomeModel.draw => BattleOutcome.draw,
    BattleOutcomeModel.cancelled => BattleOutcome.cancelled,
  };
}
