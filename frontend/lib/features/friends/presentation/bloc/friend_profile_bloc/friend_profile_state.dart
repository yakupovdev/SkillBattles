part of 'friend_profile_bloc.dart';

final class FriendProfileState extends Equatable {
  const FriendProfileState({
    this.friendId,
    this.relationshipId,
    this.loadStatus = LoadStatus.initial,
    this.profile,
    this.failure,
    this.isNoLongerFriends = false,
    this.removeStatus = LoadStatus.initial,
    this.removeFailure,
  });

  final String? friendId;
  final String? relationshipId;

  /// `success` with [profile], or with [isNoLongerFriends].
  final LoadStatus loadStatus;
  final FriendProfileEntity? profile;
  final Failure? failure;

  /// 404 FRIEND_NOT_FOUND, a REMOVED push for [relationshipId], or an own
  /// removal: [profile] is cleared; show "You are no longer friends with
  /// this player." and close the profile.
  final bool isNoLongerFriends;

  final LoadStatus removeStatus;
  final Failure? removeFailure;

  FriendProfileState copyWith({
    String? friendId,
    String? relationshipId,
    LoadStatus? loadStatus,
    FriendProfileEntity? profile,
    Failure? failure,
    bool? isNoLongerFriends,
    LoadStatus? removeStatus,
    Failure? removeFailure,
    bool resetProfile = false,
    bool resetFailure = false,
    bool resetRemoveFailure = false,
  }) {
    return FriendProfileState(
      friendId: friendId ?? this.friendId,
      relationshipId: relationshipId ?? this.relationshipId,
      loadStatus: loadStatus ?? this.loadStatus,
      profile: resetProfile ? null : profile ?? this.profile,
      failure: resetFailure ? null : failure ?? this.failure,
      isNoLongerFriends: isNoLongerFriends ?? this.isNoLongerFriends,
      removeStatus: removeStatus ?? this.removeStatus,
      removeFailure: resetRemoveFailure
          ? null
          : removeFailure ?? this.removeFailure,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    friendId,
    relationshipId,
    loadStatus,
    profile,
    failure,
    isNoLongerFriends,
    removeStatus,
    removeFailure,
  ];
}
