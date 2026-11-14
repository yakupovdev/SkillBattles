import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/account/domain/entity/activity_entity.dart';

/// Kind of unfinished activity.
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum ActivityTypeModel {
  none,
  queue,
  privateDuel,
  battle;

  ActivityType toEntity() => switch (this) {
    ActivityTypeModel.none => ActivityType.none,
    ActivityTypeModel.queue => ActivityType.queue,
    ActivityTypeModel.privateDuel => ActivityType.privateDuel,
    ActivityTypeModel.battle => ActivityType.battle,
  };
}
