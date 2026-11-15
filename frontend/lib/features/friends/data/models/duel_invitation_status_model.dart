import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/friends/domain/entity/duel_invitation_status.dart';

/// State of a room invitation.
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum DuelInvitationStatusModel {
  pending,
  accepted,
  declined,
  cancelled,
  expired;

  DuelInvitationStatus toEntity() => switch (this) {
    DuelInvitationStatusModel.pending => DuelInvitationStatus.pending,
    DuelInvitationStatusModel.accepted => DuelInvitationStatus.accepted,
    DuelInvitationStatusModel.declined => DuelInvitationStatus.declined,
    DuelInvitationStatusModel.cancelled => DuelInvitationStatus.cancelled,
    DuelInvitationStatusModel.expired => DuelInvitationStatus.expired,
  };
}
