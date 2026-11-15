import 'package:skill_battles/app/notifications/app_notification_data.dart';
import 'package:skill_battles/app/notifications/friends_notifications.dart';
import 'package:skill_battles/app/notifications/rematch_notifications.dart';
import 'package:skill_battles/features/notifications/presentation/bloc/notification_bloc/notification_bloc.dart';

/// Dispatches a [NotificationBloc] item or notice to the adapter of its kind.
///
/// A new kind is one new case in each switch here plus one adapter file next
/// to `rematch_notifications.dart`; the overlay does not change.
///
/// [openResultBattleId] is the battle whose result screen is open (or
/// `null`): the screen already shows its rematch inline, so that kind's cards,
/// hidden entries and toasts are suppressed.
abstract final class NotificationMapper {
  static bool isSuppressed(
    NotificationKind kind,
    String resourceId,
    String? openResultBattleId,
  ) => switch (kind) {
    NotificationKind.rematch => RematchNotifications.isOnOpenResult(
      resourceId,
      openResultBattleId,
    ),
    // Shown on every route; the Friends page and the room render their own
    // copies, which converge with these through the change streams.
    NotificationKind.friendRequest || NotificationKind.duelInvitation => false,
  };

  /// Cards to draw: prompts of every kind, minus the suppressed ones.
  static List<AppNotificationPrompt> prompts(
    NotificationState state,
    NotificationBloc bloc, {
    required String? openResultBattleId,
  }) => <AppNotificationPrompt>[
    for (final NotificationItem item in state.prompts)
      if (!isSuppressed(item.kind, item.resourceId, openResultBattleId))
        switch (item.payload) {
          final RematchNotificationPayload payload =>
            RematchNotifications.prompt(
              item,
              payload,
              isBusy: state.isBusy,
              bloc: bloc,
            ),
          final FriendRequestNotificationPayload payload =>
            FriendsNotifications.requestPrompt(item, payload, bloc: bloc),
          final DuelInvitationNotificationPayload payload =>
            FriendsNotifications.invitationPrompt(
              item,
              payload,
              isBusy: state.isBusy,
              bloc: bloc,
            ),
        },
  ];

  /// Hidden, still pending prompts (the pill's share).
  static List<NotificationItem> hiddenItems(
    NotificationState state,
    String? openResultBattleId,
  ) => <NotificationItem>[
    for (final NotificationItem item in state.items)
      if (item.isPrompt &&
          item.isHidden &&
          !item.isExpired &&
          !isSuppressed(item.kind, item.resourceId, openResultBattleId))
        item,
  ];

  /// Count and label of the pill over every kind; all-rematch hidden items
  /// get the rematch wording, anything else `{n} pending requests`.
  static (int, String) pill(
    NotificationState state,
    String? openResultBattleId,
  ) {
    final List<NotificationItem> hidden = hiddenItems(
      state,
      openResultBattleId,
    );
    final int count = hidden.length;
    final bool isAllRematch = hidden.every(
      (NotificationItem item) => item.kind == NotificationKind.rematch,
    );
    final String label = isAllRematch
        ? RematchNotifications.pillLabel(count)
        : (count == 1 ? '1 pending request' : '$count pending requests');
    return (count, label);
  }

  /// Whether a card or the pill is on screen (the connection indicator only
  /// shows next to those).
  static bool hasVisibleContent(
    NotificationState state,
    String? openResultBattleId,
  ) =>
      state.prompts.any(
        (NotificationItem item) =>
            !isSuppressed(item.kind, item.resourceId, openResultBattleId),
      ) ||
      hiddenItems(state, openResultBattleId).isNotEmpty;

  /// Whether the notice is dropped without a toast.
  static bool isConsumed(
    NotificationNotice notice,
    String? openResultBattleId,
  ) => isSuppressed(notice.kind, notice.resourceId, openResultBattleId);

  static AppNotificationToastData toast(NotificationNotice notice) =>
      switch (notice.kind) {
        NotificationKind.rematch => RematchNotifications.toast(notice),
        NotificationKind.friendRequest ||
        NotificationKind.duelInvitation => FriendsNotifications.toast(notice),
      };
}
