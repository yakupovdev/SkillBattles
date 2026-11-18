import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/router/app_routes.dart';

/// The routed page of `AppShell` that keeps the visited tab roots
/// ([AppRoutes.tabRoots]) mounted, like Flutter's `IndexedStack`.
///
/// A tab root stays in the tree, hidden, while another page is shown, so its
/// BLoC, loaded data, scroll offset and local state survive and going back
/// to the tab sends no request. Every other route is built in one slot and
/// replaced on navigation, as before.
///
/// The kept tabs live as long as the shell: leaving it (the live battle,
/// signing out) disposes them.
final class TabKeepAlive extends StatefulComponent {
  const TabKeepAlive({
    required this.routeName,
    required this.location,
    required this.child,
    super.key,
  });

  /// Name of the current route (an `AppRoutes.x.name`).
  final String? routeName;

  /// Current location (path and query) of the router.
  final String location;

  /// The page the router built for [location].
  final Component child;

  /// Whether a kept tab opened at [keptLocation] answers [location]: the
  /// same address, or the bare tab path a tab click opens. Another query
  /// (a deep link such as `/leaderboard?discipline=…`) needs a fresh page,
  /// because a kept page does not rebuild its BLoC from new arguments.
  static bool reusesKept({
    required String keptLocation,
    required String location,
  }) {
    if (keptLocation == location) return true;
    return Uri.parse(location).query.isEmpty;
  }

  @override
  State<TabKeepAlive> createState() => _TabKeepAliveState();
}

final class _TabKeepAliveState extends State<TabKeepAlive> {
  /// Kept tabs by route name, in the order they were first opened (the
  /// children keep their order, so no element moves).
  late Map<String, _KeptTab> _tabs;

  /// Bumped for a fresh page of a kept tab, so its key changes.
  late int _generation;

  @override
  void initState() {
    super.initState();
    _tabs = <String, _KeptTab>{};
    _generation = 0;
  }

  static bool _isTabRoot(String? name) =>
      name != null && AppRoutes.tabRoots.any((AppRoutes route) => route.name == name);

  /// Records the current tab before it is rendered.
  void _keepCurrent(String name) {
    final _KeptTab? kept = _tabs[name];
    if (kept != null &&
        TabKeepAlive.reusesKept(
          keptLocation: kept.location,
          location: component.location,
        )) {
      return;
    }
    _tabs[name] = _KeptTab(
      key: ValueKey<String>('tab:$name:${_generation++}'),
      location: component.location,
      child: component.child,
    );
  }

  @override
  Component build(BuildContext context) {
    final String? name = component.routeName;
    final bool isTab = _isTabRoot(name);
    if (isTab) _keepCurrent(name!);
    return Component.fragment(<Component>[
      for (final MapEntry<String, _KeptTab> tab in _tabs.entries)
        _TabSlot(
          key: tab.value.key,
          visible: tab.key == name,
          child: tab.value.child,
        ),
      if (!isTab)
        _TabSlot(
          key: const ValueKey<String>('route'),
          visible: true,
          child: component.child,
        ),
    ]);
  }
}

/// A kept tab: the page first built for [location].
final class _KeptTab {
  const _KeptTab({
    required this.key,
    required this.location,
    required this.child,
  });

  final Key key;
  final String location;
  final Component child;
}

/// One page box over the shell's page area. A hidden one keeps its layout
/// (and so its scroll offset) but is not painted, focusable or announced.
final class _TabSlot extends StatelessComponent {
  const _TabSlot({required this.visible, required this.child, super.key});

  final bool visible;
  final Component child;

  @override
  Component build(BuildContext context) {
    return div(
      classes: visible ? 'app-shell__tab' : 'app-shell__tab app-shell__tab--hidden',
      attributes: visible ? null : const <String, String>{'inert': '', 'aria-hidden': 'true'},
      <Component>[child],
    );
  }
}
