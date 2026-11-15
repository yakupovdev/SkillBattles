/// Why an invitation was cancelled or expired; `null` for other statuses.
enum DuelInvitationReason {
  senderCancelled,
  duelCancelled,
  duelFilled,
  friendRemoved,
  invitationExpired,
  duelExpired,
}
