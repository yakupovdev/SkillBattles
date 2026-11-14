import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/matchmaking/domain/entity/queue_status.dart';

/// State of a ranked queue entry.
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum QueueStatusModel {
  searching,
  matched,
  cancelled,
  expired;

  QueueStatus toEntity() => switch (this) {
    QueueStatusModel.searching => QueueStatus.searching,
    QueueStatusModel.matched => QueueStatus.matched,
    QueueStatusModel.cancelled => QueueStatus.cancelled,
    QueueStatusModel.expired => QueueStatus.expired,
  };
}
