import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/domain/entity/battle_status.dart';

/// Terminal battle status.
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum BattleStatusModel {
  finished,
  cancelled;

  BattleStatus toEntity() => switch (this) {
    BattleStatusModel.finished => BattleStatus.finished,
    BattleStatusModel.cancelled => BattleStatus.cancelled,
  };
}
