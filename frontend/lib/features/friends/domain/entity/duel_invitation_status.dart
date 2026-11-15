/// State of a targeted room invitation.
enum DuelInvitationStatus {
  pending,
  accepted,
  declined,
  cancelled,
  expired;

  bool get isPending => this == pending;

  bool get isTerminal => this != pending;
}
