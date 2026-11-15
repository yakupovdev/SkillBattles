import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/friends/domain/entity/relationship_status.dart';

/// State of a friendship record.
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum RelationshipStatusModel {
  pending,
  accepted,
  declined,
  cancelled,
  removed;

  RelationshipStatus toEntity() => switch (this) {
    RelationshipStatusModel.pending => RelationshipStatus.pending,
    RelationshipStatusModel.accepted => RelationshipStatus.accepted,
    RelationshipStatusModel.declined => RelationshipStatus.declined,
    RelationshipStatusModel.cancelled => RelationshipStatus.cancelled,
    RelationshipStatusModel.removed => RelationshipStatus.removed,
  };
}
