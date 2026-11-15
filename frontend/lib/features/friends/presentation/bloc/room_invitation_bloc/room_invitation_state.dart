part of 'room_invitation_bloc.dart';

final class RoomInvitationState extends Equatable {
  const RoomInvitationState({
    this.duelId,
    this.restoreStatus = LoadStatus.initial,
    this.restoreFailure,
    this.invitation,
    this.clockOffset = Duration.zero,
    this.friendsStatus = LoadStatus.initial,
    this.friends = const <FriendListItemEntity>[],
    this.friendsPage,
    this.friendsFailure,
    this.friendsPageStatus = LoadStatus.initial,
    this.friendsPageFailure,
    this.sendStatus = LoadStatus.initial,
    this.sendFailure,
    this.sendFriendId,
    this.canRetrySend = false,
    this.withdrawStatus = LoadStatus.initial,
    this.withdrawFailure,
  });

  final String? duelId;

  /// Restore of the room's invitation. 404 DUEL_NOT_FOUND = room lost.
  final LoadStatus restoreStatus;
  final Failure? restoreFailure;

  /// The room's latest invitation (any status) until cleared with
  /// [RoomInvitationResultCleared] or replaced by a new send.
  final DuelInvitationEntity? invitation;

  /// Server time minus local time, for `expiresAt` countdowns.
  final Duration clockOffset;

  final LoadStatus friendsStatus;
  final List<FriendListItemEntity> friends;
  final PageInfoEntity? friendsPage;
  final Failure? friendsFailure;

  /// Status of a page change of the picker
  /// ([RoomInvitationFriendsPageRequested]); the shown page stays visible
  /// while it loads. [friendsStatus] covers the first load.
  final LoadStatus friendsPageStatus;
  final Failure? friendsPageFailure;

  final LoadStatus sendStatus;
  final Failure? sendFailure;

  /// Target of the running or last send.
  final String? sendFriendId;

  /// The last send to [sendFriendId] failed without a definite answer; a
  /// retry reuses the same request id (show "Retry").
  final bool canRetrySend;

  final LoadStatus withdrawStatus;
  final Failure? withdrawFailure;

  DuelInvitationEntity? get pendingInvitation =>
      invitation?.status.isPending ?? false ? invitation : null;

  /// At most one pending invitation per room: picking is allowed only
  /// without one and while no send runs.
  bool get canInvite =>
      duelId != null && pendingInvitation == null && !sendStatus.isLoading;

  bool get hasPreviousFriends => friendsPage?.hasPrevious ?? false;

  bool get hasNextFriends => friendsPage?.hasNext ?? false;

  RoomInvitationState copyWith({
    String? duelId,
    LoadStatus? restoreStatus,
    Failure? restoreFailure,
    DuelInvitationEntity? invitation,
    Duration? clockOffset,
    LoadStatus? friendsStatus,
    List<FriendListItemEntity>? friends,
    PageInfoEntity? friendsPage,
    Failure? friendsFailure,
    LoadStatus? friendsPageStatus,
    Failure? friendsPageFailure,
    LoadStatus? sendStatus,
    Failure? sendFailure,
    String? sendFriendId,
    bool? canRetrySend,
    LoadStatus? withdrawStatus,
    Failure? withdrawFailure,
    bool resetRestoreFailure = false,
    bool resetInvitation = false,
    bool resetFriendsFailure = false,
    bool resetFriendsPageFailure = false,
    bool resetSendFailure = false,
    bool resetWithdrawFailure = false,
  }) {
    return RoomInvitationState(
      duelId: duelId ?? this.duelId,
      restoreStatus: restoreStatus ?? this.restoreStatus,
      restoreFailure: resetRestoreFailure
          ? null
          : restoreFailure ?? this.restoreFailure,
      invitation: resetInvitation ? null : invitation ?? this.invitation,
      clockOffset: clockOffset ?? this.clockOffset,
      friendsStatus: friendsStatus ?? this.friendsStatus,
      friends: friends ?? this.friends,
      friendsPage: friendsPage ?? this.friendsPage,
      friendsFailure: resetFriendsFailure
          ? null
          : friendsFailure ?? this.friendsFailure,
      friendsPageStatus: friendsPageStatus ?? this.friendsPageStatus,
      friendsPageFailure: resetFriendsPageFailure
          ? null
          : friendsPageFailure ?? this.friendsPageFailure,
      sendStatus: sendStatus ?? this.sendStatus,
      sendFailure: resetSendFailure ? null : sendFailure ?? this.sendFailure,
      sendFriendId: sendFriendId ?? this.sendFriendId,
      canRetrySend: canRetrySend ?? this.canRetrySend,
      withdrawStatus: withdrawStatus ?? this.withdrawStatus,
      withdrawFailure: resetWithdrawFailure
          ? null
          : withdrawFailure ?? this.withdrawFailure,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    duelId,
    restoreStatus,
    restoreFailure,
    invitation,
    clockOffset,
    friendsStatus,
    friends,
    friendsPage,
    friendsFailure,
    friendsPageStatus,
    friendsPageFailure,
    sendStatus,
    sendFailure,
    sendFriendId,
    canRetrySend,
    withdrawStatus,
    withdrawFailure,
  ];
}
