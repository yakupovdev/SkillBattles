part of 'notification_bloc.dart';

sealed class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Sent once by the app-level provider.
final class NotificationStarted extends NotificationEvent {
  const NotificationStarted();
}

/// Accept on a prompt card, by [NotificationItem.id].
final class NotificationAcceptRequested extends NotificationEvent {
  const NotificationAcceptRequested(this.id);

  final String id;

  @override
  List<Object?> get props => <Object?>[id];
}

/// Decline on a prompt card, by [NotificationItem.id].
final class NotificationDeclineRequested extends NotificationEvent {
  const NotificationDeclineRequested(this.id);

  final String id;

  @override
  List<Object?> get props => <Object?>[id];
}

/// × on a card: hides it locally, never declines.
final class NotificationHidden extends NotificationEvent {
  const NotificationHidden(this.id);

  final String id;

  @override
  List<Object?> get props => <Object?>[id];
}

/// Tap on the pending pill: shows every hidden prompt that is still
/// pending.
final class NotificationHiddenShown extends NotificationEvent {
  const NotificationHiddenShown();
}

/// Re-reads own activity (busy flag); the overlay sends it on every route
/// change.
final class NotificationActivityRefreshRequested extends NotificationEvent {
  const NotificationActivityRefreshRequested();
}

/// A battle was opened: by the overlay for [NotificationState.battleToOpen],
/// or by a screen's own navigation (the private room on MATCHED sends it
/// before navigating). The id is never exposed as `battleToOpen` again in
/// this session, so the room and the overlay never both navigate.
final class NotificationBattleOpened extends NotificationEvent {
  const NotificationBattleOpened(this.battleId);

  final String battleId;

  @override
  List<Object?> get props => <Object?>[battleId];
}

/// The overlay took the notice into its toast queue.
final class NotificationNoticeShown extends NotificationEvent {
  const NotificationNoticeShown(this.noticeId);

  final String noticeId;

  @override
  List<Object?> get props => <Object?>[noticeId];
}

final class _SignedInChanged extends NotificationEvent {
  const _SignedInChanged(this.isSignedIn);

  final bool isSignedIn;

  @override
  List<Object?> get props => <Object?>[isSignedIn];
}

final class _ConnectionChanged extends NotificationEvent {
  const _ConnectionChanged(this.status);

  final RealtimeStatus status;

  @override
  List<Object?> get props => <Object?>[status];
}

/// The local deadline of an item passed.
final class _DeadlineReached extends NotificationEvent {
  const _DeadlineReached(this.itemId);

  final String itemId;

  @override
  List<Object?> get props => <Object?>[itemId];
}

/// An expired visible card stayed on screen long enough.
final class _ExpiredLingerElapsed extends NotificationEvent {
  const _ExpiredLingerElapsed(this.itemId);

  final String itemId;

  @override
  List<Object?> get props => <Object?>[itemId];
}

// Rematch kind.

final class _RematchReceived extends NotificationEvent {
  const _RematchReceived(this.rematch);

  final RematchEntity rematch;

  @override
  List<Object?> get props => <Object?>[rematch];
}

/// Re-reads every known waiting rematch after a reconnect.
final class _RematchRecoveryRequested extends NotificationEvent {
  const _RematchRecoveryRequested();
}

/// Loads the source battle once: opponent, discipline and own id.
final class _RematchEnrichmentRequested extends NotificationEvent {
  const _RematchEnrichmentRequested(this.sourceBattleId);

  final String sourceBattleId;

  @override
  List<Object?> get props => <Object?>[sourceBattleId];
}

// Friends kinds (friend requests and room invitations).

/// The signed-in user id changed; another id than before is an account
/// switch.
final class _SignedInUserChanged extends NotificationEvent {
  const _SignedInUserChanged(this.userId);

  final String? userId;

  @override
  List<Object?> get props => <Object?>[userId];
}

/// Re-reads incoming friend requests, incoming invitations, own activity
/// and the host's own invitation. A [baseline] (sign-in, reconnect) also
/// shows every recovered prompt again.
final class _FriendsRecoveryRequested extends NotificationEvent {
  const _FriendsRecoveryRequested({this.baseline = false});

  final bool baseline;

  @override
  List<Object?> get props => <Object?>[baseline];
}

final class _FriendshipReceived extends NotificationEvent {
  const _FriendshipReceived(this.relationship);

  final RelationshipEntity relationship;

  @override
  List<Object?> get props => <Object?>[relationship];
}

final class _DuelInvitationReceived extends NotificationEvent {
  const _DuelInvitationReceived(this.invitation);

  final DuelInvitationEntity invitation;

  @override
  List<Object?> get props => <Object?>[invitation];
}
