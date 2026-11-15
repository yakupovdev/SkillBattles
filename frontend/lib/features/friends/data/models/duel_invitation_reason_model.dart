import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/friends/domain/entity/duel_invitation_reason.dart';

/// Cancellation or expiry reason of a room invitation.
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum DuelInvitationReasonModel {
  senderCancelled,
  duelCancelled,
  duelFilled,
  friendRemoved,
  invitationExpired,
  duelExpired;

  DuelInvitationReason toEntity() => switch (this) {
    DuelInvitationReasonModel.senderCancelled =>
      DuelInvitationReason.senderCancelled,
    DuelInvitationReasonModel.duelCancelled =>
      DuelInvitationReason.duelCancelled,
    DuelInvitationReasonModel.duelFilled => DuelInvitationReason.duelFilled,
    DuelInvitationReasonModel.friendRemoved =>
      DuelInvitationReason.friendRemoved,
    DuelInvitationReasonModel.invitationExpired =>
      DuelInvitationReason.invitationExpired,
    DuelInvitationReasonModel.duelExpired => DuelInvitationReason.duelExpired,
  };
}
