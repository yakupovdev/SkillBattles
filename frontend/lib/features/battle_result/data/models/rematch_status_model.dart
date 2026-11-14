import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/battle_result/domain/entity/rematch_status.dart';

/// State of a rematch consent.
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum RematchStatusModel {
  waiting,
  matched,
  expired,
  cancelled;

  RematchStatus toEntity() => switch (this) {
    RematchStatusModel.waiting => RematchStatus.waiting,
    RematchStatusModel.matched => RematchStatus.matched,
    RematchStatusModel.expired => RematchStatus.expired,
    RematchStatusModel.cancelled => RematchStatus.cancelled,
  };
}
