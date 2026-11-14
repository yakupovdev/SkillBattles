import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/account/domain/entity/activity_entity.dart';

/// Distinguishes the resource behind the activity.
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum ActivityResourceKindModel {
  queueEntry,
  duel,
  rematch,
  battle;

  ActivityResourceKind toEntity() => switch (this) {
    ActivityResourceKindModel.queueEntry => ActivityResourceKind.queueEntry,
    ActivityResourceKindModel.duel => ActivityResourceKind.duel,
    ActivityResourceKindModel.rematch => ActivityResourceKind.rematch,
    ActivityResourceKindModel.battle => ActivityResourceKind.battle,
  };
}
