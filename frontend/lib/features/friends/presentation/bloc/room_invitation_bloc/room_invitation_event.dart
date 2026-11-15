part of 'room_invitation_bloc.dart';

sealed class RoomInvitationEvent extends Equatable {
  const RoomInvitationEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Follows DUEL_INVITATION_CHANGED for [duelId] and restores the room's
/// invitation (GET /duels/{duelId}/invitations). The host's room only.
final class RoomInvitationStarted extends RoomInvitationEvent {
  const RoomInvitationStarted(this.duelId);

  final String duelId;

  @override
  List<Object?> get props => <Object?>[duelId];
}

/// Restores the invitation again (tab resume, retry).
final class RoomInvitationRefreshRequested extends RoomInvitationEvent {
  const RoomInvitationRefreshRequested();
}

/// Loads (or reloads) the first page of accepted friends for the picker.
final class RoomInvitationFriendsRequested extends RoomInvitationEvent {
  const RoomInvitationFriendsRequested();
}

/// Shows page [page] (zero-based) of the picker, replacing the friends.
/// Ignored while the picker is loading; out-of-range pages are clamped.
final class RoomInvitationFriendsPageRequested extends RoomInvitationEvent {
  const RoomInvitationFriendsPageRequested(this.page);

  final int page;

  @override
  List<Object?> get props => <Object?>[page];
}

/// Send (or retry) the invitation to [friendId] (USER id). A retry for the
/// same friend after an uncertain failure reuses the request id; another
/// friend or a send after a resolved one gets a new id. Ignored while an
/// invitation is pending or a send runs.
final class RoomInvitationSendRequested extends RoomInvitationEvent {
  const RoomInvitationSendRequested(this.friendId);

  final String friendId;

  @override
  List<Object?> get props => <Object?>[friendId];
}

/// "Cancel invitation" for the pending invitation.
final class RoomInvitationWithdrawRequested extends RoomInvitationEvent {
  const RoomInvitationWithdrawRequested();
}

/// Hides a terminal invitation (declined / expired / cancelled) so the
/// picker shows again. Ignored while the invitation is pending.
final class RoomInvitationResultCleared extends RoomInvitationEvent {
  const RoomInvitationResultCleared();
}

final class _InvitationReceived extends RoomInvitationEvent {
  const _InvitationReceived(this.invitation);

  final DuelInvitationEntity invitation;

  @override
  List<Object?> get props => <Object?>[invitation];
}

final class _Reconnected extends RoomInvitationEvent {
  const _Reconnected();
}
