import 'package:skill_battles/app/notifications/app_notification_data.dart';
import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';
import 'package:skill_battles/core/presentation/widgets/app_notification_toast.dart';
import 'package:skill_battles/features/notifications/presentation/bloc/notification_bloc/notification_bloc.dart';

/// Adapter of the rematch kind: maps a rematch item or notice of the
/// [NotificationBloc] to the generic notification view data and dispatches
/// the bloc's events from it. Called from `notification_mapper.dart`.
abstract final class RematchNotifications {
  /// A request that lives for 60 s.
  static const Duration lifetime = Duration(seconds: 60);

  /// Whether the rematch of [resourceId] (its source battle) is the one the
  /// open result screen already shows inline.
  static bool isOnOpenResult(String resourceId, String? openResultBattleId) =>
      resourceId == openResultBattleId;

  static AppNotificationPrompt prompt(
    NotificationItem item,
    RematchNotificationPayload payload, {
    required bool isBusy,
    required NotificationBloc bloc,
  }) {
    final String id = item.id;
    final String? nickname = payload.opponentNickname;
    final String? code = payload.disciplineCode;
    final NotificationActionStatus? status = item.action?.status;
    final bool isAccepting = status == NotificationActionStatus.accepting;
    final bool isDeclining = status == NotificationActionStatus.declining;
    final bool isInFlight = isAccepting || isDeclining;
    final bool isExpired = item.isExpired;
    final String what = code == null
        ? 'wants a rematch.'
        : 'wants a rematch in ${formatDisciplineCode(code)}.';

    return AppNotificationPrompt(
      id: id,
      expiresAt: item.expiresAt,
      lifetime: lifetime,
      avatarName: nickname ?? '',
      title: 'Rematch request',
      emphasis: nickname,
      text: nickname == null ? 'Your opponent $what' : ' $what',
      isExpired: isExpired,
      expiredText: 'The rematch request expired.',
      warningText: isBusy && !isExpired
          ? 'Finish or leave your current activity before accepting.'
          : null,
      errorText: status == NotificationActionStatus.failed
          ? "Couldn't update the rematch request. Try again."
          : null,
      primaryLabel: 'Accept',
      secondaryLabel: 'Decline',
      isPrimaryLoading: isAccepting,
      isSecondaryLoading: isDeclining,
      onPrimary: isExpired || isBusy || isInFlight
          ? null
          : () => bloc.add(NotificationAcceptRequested(id)),
      onSecondary: isExpired || isInFlight
          ? null
          : () => bloc.add(NotificationDeclineRequested(id)),
      // While a request is in flight the × is hidden but keeps its slot.
      onHide: isInFlight ? null : () => bloc.add(NotificationHidden(id)),
    );
  }

  /// `1 pending rematch` / `{n} pending rematches`.
  static String pillLabel(int count) =>
      count == 1 ? '1 pending rematch' : '$count pending rematches';

  static AppNotificationToastData toast(NotificationNotice notice) {
    final String? nickname = notice.playerNickname;
    final (AppNotificationToastKind, String) look = switch (notice.type) {
      NotificationNoticeType.accepted => (
        AppNotificationToastKind.success,
        'Rematch accepted. Opening the ready check…',
      ),
      NotificationNoticeType.expired => (
        AppNotificationToastKind.clock,
        'The rematch request expired.',
      ),
      NotificationNoticeType.cancelled => (
        AppNotificationToastKind.info,
        'The rematch request was cancelled.',
      ),
      NotificationNoticeType.declined => (
        AppNotificationToastKind.info,
        nickname == null
            ? 'Your opponent declined the rematch.'
            : '$nickname declined the rematch.',
      ),
    };
    return AppNotificationToastData(
      id: notice.id,
      kind: look.$1,
      message: look.$2,
    );
  }
}
