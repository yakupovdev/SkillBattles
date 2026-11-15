import 'package:skill_battles/app/notifications/app_notification_data.dart';
import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';
import 'package:skill_battles/core/presentation/widgets/app_notification_toast.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_reason.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friends_toast.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/features/notifications/presentation/bloc/notification_bloc/notification_bloc.dart';

/// Adapter of the friends kinds (friend requests and room invitations):
/// maps their [NotificationBloc] items and notices to the generic view data
/// and dispatches the bloc's events. Called from `notification_mapper.dart`.
///
/// Card copy is the copy of `FriendRequestCard` / `MatchInviteCard` (Paper
/// sheet 38); toasts reuse [FriendsToastVariant]. Host-side toasts other
/// than "accepted" have no approved copy yet and are written here.
abstract final class FriendsNotifications {
  /// Keeps the track fraction defined for a zero-length lifetime.
  static const Duration _minLifetime = Duration(seconds: 1);

  static AppNotificationPrompt requestPrompt(
    NotificationItem item,
    FriendRequestNotificationPayload payload, {
    required NotificationBloc bloc,
  }) {
    final String id = item.id;
    final String nickname = payload.relationship.requester.nickname;
    final NotificationActionStatus? status = item.action?.status;
    final bool isInFlight = item.isActionInFlight;
    final bool isDone = payload.isDone;
    return AppNotificationPrompt(
      id: id,
      expiresAt: item.expiresAt,
      hasDeadline: false,
      avatarName: nickname,
      title: 'Friend request',
      emphasis: nickname,
      text: ' wants to add you as a friend.',
      doneText: isDone ? 'You and $nickname are now friends.' : null,
      errorText: status == NotificationActionStatus.failed
          ? "Couldn't update the friend request. Try again."
          : null,
      primaryLabel: 'Accept',
      secondaryLabel: 'Decline',
      isPrimaryLoading:
          status == NotificationActionStatus.accepting ||
          status == NotificationActionStatus.reconciling,
      isSecondaryLoading: status == NotificationActionStatus.declining,
      onPrimary: isInFlight || isDone
          ? null
          : () => bloc.add(NotificationAcceptRequested(id)),
      onSecondary: isInFlight || isDone
          ? null
          : () => bloc.add(NotificationDeclineRequested(id)),
      // While a request is in flight the × is hidden but keeps its slot.
      onHide: isInFlight ? null : () => bloc.add(NotificationHidden(id)),
    );
  }

  static AppNotificationPrompt invitationPrompt(
    NotificationItem item,
    DuelInvitationNotificationPayload payload, {
    required bool isBusy,
    required NotificationBloc bloc,
  }) {
    final String id = item.id;
    final DuelInvitationEntity invitation = payload.invitation;
    final String nickname = invitation.host.nickname;
    final NotificationActionStatus? status = item.action?.status;
    final bool isAccepting =
        status == NotificationActionStatus.accepting ||
        status == NotificationActionStatus.reconciling;
    final bool isDeclining = status == NotificationActionStatus.declining;
    final bool isInFlight = item.isActionInFlight;
    final bool isClosed = item.isExpired;
    final bool isRoomUnavailable = isClosed && payload.isRoomUnavailable;
    final bool isContentUnavailable =
        status == NotificationActionStatus.failed &&
        (item.action?.failure?.hasCode(ApiErrorCodes.contentUnavailable) ??
            false);
    final Duration lifetime = invitation.expiresAt.difference(
      invitation.createdAt,
    );
    return AppNotificationPrompt(
      id: id,
      // Already on the local clock (server offset applied by the bloc).
      expiresAt: item.expiresAt,
      lifetime: lifetime < _minLifetime ? _minLifetime : lifetime,
      avatarName: nickname,
      title: 'Match invitation',
      emphasis: nickname,
      text:
          ' invited you to a private '
          '${formatDisciplineCode(invitation.disciplineCode)} match.',
      isExpired: isClosed,
      deadlineLabel: isRoomUnavailable ? '—' : null,
      expiredText: isRoomUnavailable
          ? 'This room is no longer available.'
          : 'This invitation expired.',
      warningText: isClosed
          ? null
          : isContentUnavailable
          ? 'Questions for this discipline are unavailable right now. '
                'Try again in a moment.'
          : isBusy
          ? 'Finish or leave your current activity before accepting.'
          : null,
      errorText:
          status == NotificationActionStatus.failed &&
              !isContentUnavailable &&
              !isBusy
          ? "Couldn't update the invitation. Try again."
          : null,
      primaryLabel: 'Accept',
      secondaryLabel: 'Decline',
      isPrimaryLoading: isAccepting,
      isSecondaryLoading: isDeclining,
      onPrimary: isClosed || isBusy || isInFlight
          ? null
          : () => bloc.add(NotificationAcceptRequested(id)),
      onSecondary: isClosed || isInFlight
          ? null
          : () => bloc.add(NotificationDeclineRequested(id)),
      onHide: isInFlight ? null : () => bloc.add(NotificationHidden(id)),
    );
  }

  static AppNotificationToastData toast(NotificationNotice notice) {
    final (AppNotificationToastKind, String) look = switch (notice.kind) {
      NotificationKind.friendRequest => _variant(
        FriendsToastVariant.friendRequestAccepted,
        notice.playerNickname,
      ),
      _ when notice.type == NotificationNoticeType.accepted => _variant(
        FriendsToastVariant.invitationAccepted,
        null,
      ),
      _ when notice.isOutgoing => _hostLook(notice),
      _ when notice.type == NotificationNoticeType.expired => _variant(
        FriendsToastVariant.invitationExpired,
        null,
      ),
      _ => _variant(FriendsToastVariant.invitationCancelled, null),
    };
    return AppNotificationToastData(
      id: notice.id,
      kind: look.$1,
      message: look.$2,
    );
  }

  static (AppNotificationToastKind, String) _variant(
    FriendsToastVariant variant,
    String? nickname,
  ) => (variant.kind, variant.message(nickname: nickname));

  /// The host's own invitation ended without being accepted.
  static (AppNotificationToastKind, String) _hostLook(
    NotificationNotice notice,
  ) {
    final String? nickname = notice.playerNickname;
    return switch (notice.type) {
      NotificationNoticeType.declined => (
        AppNotificationToastKind.info,
        nickname == null
            ? 'Your match invitation was declined.'
            : '$nickname declined your match invitation.',
      ),
      NotificationNoticeType.expired => (
        AppNotificationToastKind.clock,
        'Your match invitation expired.',
      ),
      _ => (
        AppNotificationToastKind.info,
        notice.invitationReason == DuelInvitationReason.friendRemoved
            ? 'You are no longer friends with this player.'
            : 'Your match invitation was cancelled.',
      ),
    };
  }
}
