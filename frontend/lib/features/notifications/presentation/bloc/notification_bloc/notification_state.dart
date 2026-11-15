part of 'notification_bloc.dart';

/// Source of a notification. A new kind adds a [NotificationPayload]
/// subclass and its handlers in [NotificationBloc].
enum NotificationKind {
  rematch,

  /// An incoming PENDING friend request (resource id: relationship id).
  friendRequest,

  /// A targeted private-room invitation (resource id: invitation id):
  /// incoming ones are prompts, the host's own outgoing one is tracked only
  /// for notices and navigation.
  duelInvitation,
}

/// Kind-specific data of a [NotificationItem].
sealed class NotificationPayload extends Equatable {
  const NotificationPayload();
}

/// A rematch consent of a terminal private battle.
final class RematchNotificationPayload extends NotificationPayload {
  const RematchNotificationPayload({
    required this.rematch,
    required this.isIncoming,
    this.opponentNickname,
    this.disciplineCode,
  });

  final RematchEntity rematch;

  /// Waiting for this player's consent; `false` once this player consented.
  final bool isIncoming;

  /// `null` until (or when failing) the source battle is loaded.
  final String? opponentNickname;
  final String? disciplineCode;

  RematchNotificationPayload copyWith({
    RematchEntity? rematch,
    bool? isIncoming,
    String? opponentNickname,
    String? disciplineCode,
  }) {
    return RematchNotificationPayload(
      rematch: rematch ?? this.rematch,
      isIncoming: isIncoming ?? this.isIncoming,
      opponentNickname: opponentNickname ?? this.opponentNickname,
      disciplineCode: disciplineCode ?? this.disciplineCode,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    rematch,
    isIncoming,
    opponentNickname,
    disciplineCode,
  ];
}

/// An incoming friend request (friends kind).
final class FriendRequestNotificationPayload extends NotificationPayload {
  const FriendRequestNotificationPayload({
    required this.relationship,
    this.isDone = false,
  });

  final RelationshipEntity relationship;

  /// This player's own Accept went through: the card shows "You and
  /// {nickname} are now friends." until it is removed.
  final bool isDone;

  @override
  List<Object?> get props => <Object?>[relationship, isDone];
}

/// A private-room invitation (friends kind): incoming
/// ([DuelInvitationEntity.isIncoming]) or the host's own outgoing one.
final class DuelInvitationNotificationPayload extends NotificationPayload {
  const DuelInvitationNotificationPayload({
    required this.invitation,
    this.isGone = false,
  });

  /// The latest known record; on a closed card its status and reason say
  /// why ([isRoomUnavailable]).
  final DuelInvitationEntity invitation;

  /// The server no longer knows the invitation (404 after the activity
  /// check): shown as "This room is no longer available."
  final bool isGone;

  /// The room is gone: cancelled or filled, the room expired, or [isGone].
  bool get isRoomUnavailable =>
      isGone ||
      invitation.reason == DuelInvitationReason.duelCancelled ||
      invitation.reason == DuelInvitationReason.duelFilled ||
      invitation.reason == DuelInvitationReason.duelExpired;

  @override
  List<Object?> get props => <Object?>[invitation, isGone];
}

/// What is happening to one card.
enum NotificationActionStatus {
  accepting,
  declining,

  /// The outcome of an Accept or Decline was uncertain; the resource and own
  /// activity are being re-read before anything is assumed (friends kinds).
  reconciling,

  /// The last Accept or Decline failed; [NotificationAction.failure] says
  /// why. The item is still pending and can be retried.
  failed;

  /// A request of this card is in flight.
  bool get isInFlight => this != failed;
}

/// Per-card action state. A card without one is idle.
final class NotificationAction extends Equatable {
  const NotificationAction({required this.status, this.failure});

  final NotificationActionStatus status;
  final Failure? failure;

  @override
  List<Object?> get props => <Object?>[status, failure];
}

/// One notification of interest: a prompt card, or an own request tracked
/// only for notices and navigation.
final class NotificationItem extends Equatable {
  NotificationItem({
    required this.kind,
    required this.resourceId,
    required this.expiresAt,
    required this.isPrompt,
    required this.payload,
    this.isHidden = false,
    this.isExpired = false,
    this.action,
  }) : id = idOf(kind, resourceId);

  /// `'<kind.name>:<resourceId>'`, e.g. `'rematch:<sourceBattleId>'`,
  /// `'friendRequest:<relationshipId>'`, `'duelInvitation:<invitationId>'`.
  final String id;
  final NotificationKind kind;

  /// Id of the server resource (for a rematch: the source battle id).
  final String resourceId;

  /// Local-clock deadline, also the card order. A room invitation's server
  /// `expiresAt` is converted with the server clock offset; a friend request
  /// (no deadline) gets [noDeadline] + its creation time, so it sorts after
  /// every card with a deadline, oldest first.
  final DateTime expiresAt;

  /// Shown as a card (an incoming rematch); `false` for an own outgoing
  /// rematch.
  final bool isPrompt;

  /// Hidden locally with ×.
  final bool isHidden;

  /// The deadline passed; a visible card stays briefly in this state.
  final bool isExpired;
  final NotificationAction? action;
  final NotificationPayload payload;

  static String idOf(NotificationKind kind, String resourceId) =>
      '${kind.name}:$resourceId';

  /// Base of the sort key of cards without a deadline.
  static final DateTime noDeadline = DateTime.utc(100000);

  /// Whether [expiresAt] is a real deadline (not [noDeadline]-based).
  bool get hasDeadline => expiresAt.isBefore(noDeadline);

  bool get isActionInFlight => action?.status.isInFlight ?? false;

  NotificationItem copyWith({
    DateTime? expiresAt,
    bool? isPrompt,
    bool? isHidden,
    bool? isExpired,
    NotificationAction? action,
    NotificationPayload? payload,
    bool resetAction = false,
  }) {
    return NotificationItem(
      kind: kind,
      resourceId: resourceId,
      expiresAt: expiresAt ?? this.expiresAt,
      isPrompt: isPrompt ?? this.isPrompt,
      isHidden: isHidden ?? this.isHidden,
      isExpired: isExpired ?? this.isExpired,
      action: resetAction ? null : action ?? this.action,
      payload: payload ?? this.payload,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    kind,
    resourceId,
    expiresAt,
    isPrompt,
    isHidden,
    isExpired,
    action,
    payload,
  ];
}

/// Kind of a one-off toast.
enum NotificationNoticeType {
  /// Both agreed; the app opens the ready check.
  accepted,

  /// An own request, or a prompt hidden with ×, expired.
  expired,

  /// The other player withdrew a prompt (for a room invitation: or the
  /// server cancelled it; see [NotificationNotice.invitationReason]).
  cancelled,

  /// The other player ended this player's own request.
  declined,
}

/// One-off notice for a toast; consumed with [NotificationNoticeShown].
final class NotificationNotice extends Equatable {
  const NotificationNotice({
    required this.id,
    required this.kind,
    required this.type,
    required this.resourceId,
    this.playerNickname,
    this.isOutgoing = false,
    this.invitationReason,
  });

  /// Unique within the app session.
  final String id;
  final NotificationKind kind;
  final NotificationNoticeType type;
  final String resourceId;

  /// The other player; `null` when unknown.
  final String? playerNickname;

  /// About this player's own request (own outgoing friend request, the
  /// host's own room invitation) rather than an incoming prompt.
  final bool isOutgoing;

  /// Room invitation only: why it was cancelled or expired.
  final DuelInvitationReason? invitationReason;

  @override
  List<Object?> get props => <Object?>[
    id,
    kind,
    type,
    resourceId,
    playerNickname,
    isOutgoing,
    invitationReason,
  ];
}

/// App-scope notifications of the signed-in user: prompt cards, own
/// requests (not shown), one-off notices and the battle to open.
final class NotificationState extends Equatable {
  const NotificationState({
    this.items = const <NotificationItem>[],
    this.notices = const <NotificationNotice>[],
    this.battleToOpen,
    this.isBusy = false,
    this.isConnected = false,
  });

  final List<NotificationItem> items;

  /// Toast queue, oldest first.
  final List<NotificationNotice> notices;

  /// New battle to navigate to; cleared with [NotificationBattleOpened].
  final String? battleToOpen;

  /// Own activity is not none (queue, room, pending rematch, battle):
  /// Accept of a rematch or room invitation is disabled; Decline stays.
  final bool isBusy;

  /// The personal realtime stream is connected.
  final bool isConnected;

  /// Visible prompt cards, soonest deadline first, including expired ones
  /// that still linger.
  List<NotificationItem> get prompts {
    final List<NotificationItem> visible =
        items
            .where((NotificationItem item) => item.isPrompt && !item.isHidden)
            .toList()
          ..sort(
            (NotificationItem a, NotificationItem b) =>
                a.expiresAt.compareTo(b.expiresAt),
          );
    return List<NotificationItem>.unmodifiable(visible);
  }

  /// Prompts hidden with × that are still pending, across all kinds.
  int get hiddenCount => items
      .where(
        (NotificationItem item) =>
            item.isPrompt && item.isHidden && !item.isExpired,
      )
      .length;

  /// The item with [NotificationItem.id] [id], if any.
  NotificationItem? item(String id) {
    for (final NotificationItem item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  NotificationState copyWith({
    List<NotificationItem>? items,
    List<NotificationNotice>? notices,
    String? battleToOpen,
    bool? isBusy,
    bool? isConnected,
    bool resetBattleToOpen = false,
  }) {
    return NotificationState(
      items: items ?? this.items,
      notices: notices ?? this.notices,
      battleToOpen: resetBattleToOpen
          ? null
          : battleToOpen ?? this.battleToOpen,
      isBusy: isBusy ?? this.isBusy,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    items,
    notices,
    battleToOpen,
    isBusy,
    isConnected,
  ];
}
