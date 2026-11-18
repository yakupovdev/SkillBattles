import 'dart:async';

import 'package:bloc_signals_jaspr/bloc_signals_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

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
/// nothing when there is nothing to show and never blocks the page under it
/// (only its own cards take clicks).
///
/// Reads the one app-scope [NotificationBloc]. A new notification kind is
/// handled in `notification_mapper.dart` (one case per switch plus an adapter
/// file like `rematch_notifications.dart`); this component does not change.
final class AppNotificationsOverlay extends StatefulComponent {
  const AppNotificationsOverlay({
    required this.routeName,
    required this.pathParameters,
    super.key,
  });

  /// Name of the current route (`AppRoutes.x.name`).
  final String? routeName;
  final Map<String, String> pathParameters;

  @override
  State<AppNotificationsOverlay> createState() => _AppNotificationsOverlayState();
}

final class _AppNotificationsOverlayState extends State<AppNotificationsOverlay> {
  late ValueNotifier<List<AppNotificationToastData>> _toasts;
  late Map<String, Timer> _timers;
  late Set<String> _takenNotices;

  @override
  void initState() {
    super.initState();
    _toasts = ValueNotifier<List<AppNotificationToastData>>(const <AppNotificationToastData>[]);
    _timers = <String, Timer>{};
    _takenNotices = <String>{};
    // The overlay is unmounted outside the shell (live battle, auth) while
    // the bloc keeps working, and a listener never fires for the state it
    // mounts with. What piled up meanwhile is stale: consume it without
    // toasts or navigation, so it never resurfaces later.
    context.binding.addPostFrameCallback(() {
      if (mounted) _dropStale(context.read<NotificationBloc>());
    });
  }

  void _dropStale(NotificationBloc bloc) {
    final NotificationState state = bloc.stateValue;
    final String? battleId = state.battleToOpen;
    if (battleId != null) bloc.add(NotificationBattleOpened(battleId));
    for (final NotificationNotice notice in state.notices) {
      if (_takenNotices.add(notice.id)) {
        bloc.add(NotificationNoticeShown(notice.id));
      }
    }
  }

  @override
  void didUpdateComponent(AppNotificationsOverlay oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.routeName != component.routeName ||
        !_mapEquals(oldComponent.pathParameters, component.pathParameters)) {
      context.read<NotificationBloc>().add(const NotificationActivityRefreshRequested());
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

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final MapEntry<String, String> entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  /// Battle whose result screen is open, if any.
  String? get _openResultBattleId =>
      component.routeName == AppRoutes.battleResult.name ? component.pathParameters[AppRoutes.battleIdParam] : null;

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
    _takenNotices.retainWhere((String id) => state.notices.any((NotificationNotice n) => n.id == id));
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
  Component build(BuildContext context) {
    final String? openResultBattleId = _openResultBattleId;
    return MultiBlocSignalListener(
      listeners: <BlocSignalListenerSingleChildComponent>[
        BlocSignalListener<NotificationBloc, NotificationState>(
          listenWhen: (NotificationState previous, NotificationState current) =>
              previous.battleToOpen != current.battleToOpen && current.battleToOpen != null,
          listener: _onBattleToOpen,
        ),
        BlocSignalListener<NotificationBloc, NotificationState>(
          listenWhen: (NotificationState previous, NotificationState current) =>
              previous.notices != current.notices && current.notices.isNotEmpty,
          listener: _onNotices,
        ),
      ],
      child: div(classes: 'app-notifications', <Component>[
        _ConnectionIndicator(openResultBattleId: openResultBattleId),
        _Pill(openResultBattleId: openResultBattleId),
        _Cards(openResultBattleId: openResultBattleId),
        _Toasts(toasts: _toasts),
      ]),
    );
  }
}

final class _ConnectionIndicator extends StatelessComponent {
  const _ConnectionIndicator({required this.openResultBattleId});

  final String? openResultBattleId;

  @override
  Component build(BuildContext context) {
    return BlocSignalSelector<NotificationBloc, NotificationState, bool>(
      selector: (NotificationState state) =>
          !state.isConnected && NotificationMapper.hasVisibleContent(state, openResultBattleId),
      builder: (BuildContext context, bool isVisible) =>
          isVisible ? const AppConnectionIndicator() : const Component.empty(),
    );
  }
}

final class _Pill extends StatelessComponent {
  const _Pill({required this.openResultBattleId});

  final String? openResultBattleId;

  @override
  Component build(BuildContext context) {
    // A record has value equality, so the pill rebuilds only on a change.
    return BlocSignalSelector<NotificationBloc, NotificationState, (int, String)>(
      selector: (NotificationState state) => NotificationMapper.pill(state, openResultBattleId),
      builder: (BuildContext context, (int, String) pill) {
        if (pill.$1 == 0) return const Component.empty();
        return AppNotificationPill(
          label: pill.$2,
          onPressed: () => context.read<NotificationBloc>().add(const NotificationHiddenShown()),
        );
      },
    );
  }
}

final class _Cards extends StatelessComponent {
  const _Cards({required this.openResultBattleId});

  final String? openResultBattleId;

  @override
  Component build(BuildContext context) {
    // The compared fields have stable identity between unrelated emissions,
    // so the cards rebuild only when a request changes.
    return BlocSignalBuilder<NotificationBloc, NotificationState>(
      buildWhen: (NotificationState previous, NotificationState current) =>
          previous.items != current.items || previous.isBusy != current.isBusy,
      builder: (BuildContext context, NotificationState state) {
        final List<AppNotificationPrompt> prompts = AppNotificationPrompt.mergeVisible(<List<AppNotificationPrompt>>[
          NotificationMapper.prompts(
            state,
            context.read<NotificationBloc>(),
            openResultBattleId: openResultBattleId,
          ),
        ]);
        if (prompts.isEmpty) return const Component.empty();
        return _CardList(prompts: prompts);
      },
    );
  }
}

final class _CardList extends StatelessComponent {
  const _CardList({required this.prompts});

  final List<AppNotificationPrompt> prompts;

  @override
  Component build(BuildContext context) {
    return div(classes: 'app-notifications__stack', <Component>[
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
    ]);
  }
}

final class _Toasts extends StatelessComponent {
  const _Toasts({required this.toasts});

  final ValueNotifier<List<AppNotificationToastData>> toasts;

  @override
  Component build(BuildContext context) {
    return ValueListenableBuilder<List<AppNotificationToastData>>(
      listenable: toasts,
      builder: (BuildContext context, List<AppNotificationToastData> value) {
        if (value.isEmpty) return const Component.empty();
        return div(classes: 'app-notifications__stack', <Component>[
          for (final AppNotificationToastData toast in value)
            AppNotificationToast(key: ValueKey<String>(toast.id), kind: toast.kind, message: toast.message),
        ]);
      },
    );
  }
}

@css
List<StyleRule> get appNotificationsOverlayStyles => <StyleRule>[
  css('.app-notifications').styles(
    display: Display.flex,
    position: const Position.absolute(top: Unit.pixels(16), right: Unit.pixels(64)),
    zIndex: const ZIndex(800),
    width: const Unit.pixels(380),
    maxWidth: const Unit.expression('calc(100% - 32px)'),
    pointerEvents: PointerEvents.none,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.end,
    gap: const Gap.row(Unit.pixels(12)),
  ),
  css('.app-notifications > *').styles(pointerEvents: PointerEvents.auto),
  css('.app-notifications__stack').styles(
    display: Display.flex,
    width: const Unit.percent(100),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(12)),
  ),
  css.media(const MediaQuery.screen(maxWidth: Unit.pixels(380 + 64 * 2)), <StyleRule>[
    css('.app-notifications').styles(
      position: const Position.absolute(top: Unit.pixels(16), right: Unit.pixels(16)),
    ),
  ]),
];
