import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/notifications/app_notification_data.dart';
import 'package:skill_battles/app/notifications/notification_mapper.dart';
import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/router/app_routes.dart';
import 'package:skill_battles/core/presentation/widgets/app_connection_indicator.dart';
import 'package:skill_battles/core/presentation/widgets/app_notification_card.dart';
import 'package:skill_battles/core/presentation/widgets/app_notification_pill.dart';
import 'package:skill_battles/core/presentation/widgets/app_notification_toast.dart';
import 'package:skill_battles/features/notifications/presentation/bloc/notification_bloc/notification_bloc.dart';

/// How long a toast stays on screen.
const Duration _toastLifetime = Duration(seconds: 4);

/// The global in-app notifications layer, mounted once in `AppShell` above
/// the routed page and below the top bar.
///
/// Column, top to bottom: connection indicator, pending pill, at most three
/// cards (all sources merged, soonest deadline first), toasts. It draws
/// nothing when there is nothing to show and never blocks the page under it.
///
/// Reads the one app-scope [NotificationBloc]. A new notification kind is
/// handled in `notification_mapper.dart` (one case per switch plus an adapter
/// file like `rematch_notifications.dart`); this widget does not change.
final class AppNotificationsOverlay extends StatefulWidget {
  const AppNotificationsOverlay({
    required this.routeName,
    required this.pathParameters,
    super.key,
  });

  /// Name of the current route (`GoRoute.name`).
  final String? routeName;
  final Map<String, String> pathParameters;

  @override
  State<AppNotificationsOverlay> createState() =>
      _AppNotificationsOverlayState();
}

final class _AppNotificationsOverlayState
    extends State<AppNotificationsOverlay> {
  late ValueNotifier<List<AppNotificationToastData>> _toasts;
  late Map<String, Timer> _timers;
  late Set<String> _takenNotices;

  @override
  void initState() {
    super.initState();
    _toasts = ValueNotifier<List<AppNotificationToastData>>(
      const <AppNotificationToastData>[],
    );
    _timers = <String, Timer>{};
    _takenNotices = <String>{};
    // The overlay is unmounted outside the shell (live battle, auth) while
    // the bloc keeps working, and a BlocListener never fires for the state
    // it mounts with. What piled up meanwhile is stale: consume it without
    // toasts or navigation, so it never resurfaces later.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _dropStale(context.read<NotificationBloc>());
    });
  }

  void _dropStale(NotificationBloc bloc) {
    final NotificationState state = bloc.state;
    final String? battleId = state.battleToOpen;
    if (battleId != null) bloc.add(NotificationBattleOpened(battleId));
    for (final NotificationNotice notice in state.notices) {
      if (_takenNotices.add(notice.id)) {
        bloc.add(NotificationNoticeShown(notice.id));
      }
    }
  }

  @override
  void didUpdateWidget(AppNotificationsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeName != widget.routeName ||
        !mapEquals(oldWidget.pathParameters, widget.pathParameters)) {
      context.read<NotificationBloc>().add(
        const NotificationActivityRefreshRequested(),
      );
    }
  }

  @override
  void dispose() {
    for (final Timer timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _toasts.dispose();
    super.dispose();
  }

  /// Battle whose result screen is open, if any.
  String? get _openResultBattleId =>
      widget.routeName == AppRoutes.battleResult.name
      ? widget.pathParameters[AppRoutes.battleIdParam]
      : null;

  void _onBattleToOpen(BuildContext context, NotificationState state) {
    final String? battleId = state.battleToOpen;
    if (battleId == null) return;
    // Always navigate: the battle route is outside the shell, so this
    // overlay is never mounted on it, and when the source result screen
    // navigates too, a second go to the same location is a no-op.
    context.goBattle(battleId);
    context.read<NotificationBloc>().add(NotificationBattleOpened(battleId));
  }

  void _onNotices(BuildContext context, NotificationState state) {
    final NotificationBloc bloc = context.read<NotificationBloc>();
    // Ids are only needed while the bloc still holds the notice.
    _takenNotices.retainWhere(
      (String id) => state.notices.any((NotificationNotice n) => n.id == id),
    );
    for (final NotificationNotice notice in state.notices) {
      if (!_takenNotices.add(notice.id)) continue;
      if (!NotificationMapper.isConsumed(notice, _openResultBattleId)) {
        _showToast(NotificationMapper.toast(notice));
      }
      bloc.add(NotificationNoticeShown(notice.id));
    }
  }

  void _showToast(AppNotificationToastData toast) {
    _toasts.value = <AppNotificationToastData>[..._toasts.value, toast];
    _timers[toast.id] = Timer(_toastLifetime, () {
      _timers.remove(toast.id);
      _toasts.value = <AppNotificationToastData>[
        for (final AppNotificationToastData item in _toasts.value)
          if (item.id != toast.id) item,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final String? openResultBattleId = _openResultBattleId;
    return Positioned.fill(
      child: MultiBlocListener(
        listeners: <BlocListener<dynamic, dynamic>>[
          BlocListener<NotificationBloc, NotificationState>(
            listenWhen:
                (NotificationState previous, NotificationState current) =>
                    previous.battleToOpen != current.battleToOpen &&
                    current.battleToOpen != null,
            listener: _onBattleToOpen,
          ),
          BlocListener<NotificationBloc, NotificationState>(
            listenWhen:
                (NotificationState previous, NotificationState current) =>
                    previous.notices != current.notices &&
                    current.notices.isNotEmpty,
            listener: _onNotices,
          ),
        ],
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isNarrow = constraints.maxWidth < 380 + 64 * 2;
            final double width = isNarrow ? constraints.maxWidth - 32 : 380;
            return Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(top: 16, right: isNarrow ? 16 : 64),
                child: SizedBox(
                  width: width < 0 ? 0 : width,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      _ConnectionIndicator(
                        openResultBattleId: openResultBattleId,
                      ),
                      _Pill(openResultBattleId: openResultBattleId),
                      _Cards(openResultBattleId: openResultBattleId),
                      _Toasts(toasts: _toasts),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Gap under a non-empty block of the column.
final class _Gap extends StatelessWidget {
  const _Gap({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(bottom: 12), child: child);
}

final class _ConnectionIndicator extends StatelessWidget {
  const _ConnectionIndicator({required this.openResultBattleId});

  final String? openResultBattleId;

  @override
  Widget build(BuildContext context) {
    final bool isVisible = context.select(
      (NotificationBloc bloc) =>
          !bloc.state.isConnected &&
          NotificationMapper.hasVisibleContent(bloc.state, openResultBattleId),
    );
    if (!isVisible) return const SizedBox.shrink();
    return const _Gap(child: AppConnectionIndicator());
  }
}

final class _Pill extends StatelessWidget {
  const _Pill({required this.openResultBattleId});

  final String? openResultBattleId;

  @override
  Widget build(BuildContext context) {
    // A record has value equality, so the pill rebuilds only on a change.
    final (int, String) pill = context.select(
      (NotificationBloc bloc) =>
          NotificationMapper.pill(bloc.state, openResultBattleId),
    );
    if (pill.$1 == 0) return const SizedBox.shrink();
    return _Gap(
      child: AppNotificationPill(
        label: pill.$2,
        onPressed: () => context.read<NotificationBloc>().add(
          const NotificationHiddenShown(),
        ),
      ),
    );
  }
}

final class _Cards extends StatelessWidget {
  const _Cards({required this.openResultBattleId});

  final String? openResultBattleId;

  @override
  Widget build(BuildContext context) {
    // The selected fields have stable identity between unrelated emissions,
    // so the cards rebuild only when a request changes.
    context.select((NotificationBloc bloc) => bloc.state.items);
    context.select((NotificationBloc bloc) => bloc.state.isBusy);
    final NotificationBloc bloc = context.read<NotificationBloc>();
    final List<AppNotificationPrompt> prompts =
        AppNotificationPrompt.mergeVisible(<List<AppNotificationPrompt>>[
          NotificationMapper.prompts(
            bloc.state,
            bloc,
            openResultBattleId: openResultBattleId,
          ),
        ]);
    if (prompts.isEmpty) return const SizedBox.shrink();
    return _Gap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: <Widget>[
          for (final AppNotificationPrompt prompt in prompts)
            AppNotificationCard(
              key: ValueKey<String>(prompt.id),
              avatarName: prompt.avatarName,
              title: prompt.title,
              emphasis: prompt.emphasis,
              text: prompt.text,
              expiresAt: prompt.hasDeadline ? prompt.expiresAt : null,
              deadlineLabel: prompt.deadlineLabel,
              doneText: prompt.doneText,
              lifetime: prompt.lifetime,
              clockOffset: prompt.clockOffset,
              isExpired: prompt.isExpired,
              expiredText: prompt.expiredText,
              warningText: prompt.warningText,
              errorText: prompt.errorText,
              primaryLabel: prompt.primaryLabel,
              secondaryLabel: prompt.secondaryLabel,
              onPrimary: prompt.onPrimary,
              onSecondary: prompt.onSecondary,
              isPrimaryLoading: prompt.isPrimaryLoading,
              isSecondaryLoading: prompt.isSecondaryLoading,
              onHide: prompt.onHide,
            ),
        ],
      ),
    );
  }
}

final class _Toasts extends StatelessWidget {
  const _Toasts({required this.toasts});

  final ValueNotifier<List<AppNotificationToastData>> toasts;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<AppNotificationToastData>>(
      valueListenable: toasts,
      builder:
          (
            BuildContext context,
            List<AppNotificationToastData> value,
            Widget? child,
          ) {
            if (value.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: <Widget>[
                for (final AppNotificationToastData toast in value)
                  AppNotificationToast(
                    key: ValueKey<String>(toast.id),
                    kind: toast.kind,
                    message: toast.message,
                  ),
              ],
            );
          },
    );
  }
}
