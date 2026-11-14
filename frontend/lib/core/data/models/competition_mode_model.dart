import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/domain/entity/battle_mode.dart';

/// Competition type; PRIVATE never changes Elo.
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum CompetitionModeModel {
  ranked,
  private;

  BattleMode toEntity() => switch (this) {
    CompetitionModeModel.ranked => BattleMode.ranked,
    CompetitionModeModel.private => BattleMode.private,
  };

  static CompetitionModeModel fromEntity(BattleMode mode) => switch (mode) {
    BattleMode.ranked => CompetitionModeModel.ranked,
    BattleMode.private => CompetitionModeModel.private,
  };
}
