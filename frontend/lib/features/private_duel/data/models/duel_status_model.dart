import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/private_duel/domain/entity/duel_status.dart';

/// State of a private room.
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum DuelStatusModel {
  waiting,
  matched,
  cancelled,
  expired;

  DuelStatus toEntity() => switch (this) {
    DuelStatusModel.waiting => DuelStatus.waiting,
    DuelStatusModel.matched => DuelStatus.matched,
    DuelStatusModel.cancelled => DuelStatus.cancelled,
    DuelStatusModel.expired => DuelStatus.expired,
  };
}
