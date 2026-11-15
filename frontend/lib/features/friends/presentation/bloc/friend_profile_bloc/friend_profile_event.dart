part of 'friend_profile_bloc.dart';

sealed class FriendProfileEvent extends Equatable {
  const FriendProfileEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Loads the profile of [friendId] (USER id) and follows FRIENDSHIP_CHANGED.
/// Pass [relationshipId] when known (from the Friends list): a REMOVED push
/// for exactly that id clears the profile at once; without it, removals of
/// this user are confirmed by refetching.
final class FriendProfileStarted extends FriendProfileEvent {
  const FriendProfileStarted({required this.friendId, this.relationshipId});

  final String friendId;
  final String? relationshipId;

  @override
  List<Object?> get props => <Object?>[friendId, relationshipId];
}

final class FriendProfileRefreshRequested extends FriendProfileEvent {
  const FriendProfileRefreshRequested();
}

/// Removes the friend (after the destructive confirmation).
final class FriendProfileRemoveRequested extends FriendProfileEvent {
  const FriendProfileRemoveRequested();
}

final class _FriendshipChanged extends FriendProfileEvent {
  const _FriendshipChanged(this.relationship);

  final RelationshipEntity relationship;

  @override
  List<Object?> get props => <Object?>[relationship];
}

final class _Reconnected extends FriendProfileEvent {
  const _Reconnected();
}
