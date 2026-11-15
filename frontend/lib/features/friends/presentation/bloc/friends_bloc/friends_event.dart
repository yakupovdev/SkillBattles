part of 'friends_bloc.dart';

sealed class FriendsEvent extends Equatable {
  const FriendsEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Subscribes to FRIENDSHIP_CHANGED and reconnects, then loads the code and
/// the first page of friends, incoming and outgoing requests in parallel.
final class FriendsStarted extends FriendsEvent {
  const FriendsStarted();
}

/// Reloads the current page of every list (and the code when it failed):
/// pull-to-refresh, tab resume, a retry button.
final class FriendsRefreshRequested extends FriendsEvent {
  const FriendsRefreshRequested();
}

/// Shows page [page] (zero-based) of [list], replacing its items. Ignored
/// while that list is loading; a page past the end loads the last page.
final class FriendsPageRequested extends FriendsEvent {
  const FriendsPageRequested(this.list, this.page);

  final FriendsList list;
  final int page;

  @override
  List<Object?> get props => <Object?>[list, page];
}

/// Retries the current page of one list (its own error view).
final class FriendsListRetryRequested extends FriendsEvent {
  const FriendsListRetryRequested(this.list);

  final FriendsList list;

  @override
  List<Object?> get props => <Object?>[list];
}

/// Add-friend form submit (built after `formKey.currentState.validate()`).
final class FriendRequestSubmitted extends FriendsEvent {
  const FriendRequestSubmitted(this.params);

  final SendFriendRequestParamsEntity params;

  @override
  List<Object?> get props => <Object?>[params];
}

final class FriendRequestAcceptRequested extends FriendsEvent {
  const FriendRequestAcceptRequested(this.requestId);

  final String requestId;

  @override
  List<Object?> get props => <Object?>[requestId];
}

final class FriendRequestDeclineRequested extends FriendsEvent {
  const FriendRequestDeclineRequested(this.requestId);

  final String requestId;

  @override
  List<Object?> get props => <Object?>[requestId];
}

/// Cancels an own outgoing PENDING request.
final class FriendRequestCancelRequested extends FriendsEvent {
  const FriendRequestCancelRequested(this.requestId);

  final String requestId;

  @override
  List<Object?> get props => <Object?>[requestId];
}

/// Removes an accepted friend (after the destructive confirmation).
final class FriendRemoveRequested extends FriendsEvent {
  const FriendRemoveRequested(this.friendId);

  /// The friend's USER id.
  final String friendId;

  @override
  List<Object?> get props => <Object?>[friendId];
}

final class _FriendshipChanged extends FriendsEvent {
  const _FriendshipChanged(this.relationship);

  final RelationshipEntity relationship;

  @override
  List<Object?> get props => <Object?>[relationship];
}

final class _Reconnected extends FriendsEvent {
  const _Reconnected();
}

final class _InvalidatedListsFlushed extends FriendsEvent {
  const _InvalidatedListsFlushed();
}
