import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// A screen that wraps itself in the providers it needs (for example a
/// `BlocProvider` built from use cases) before it is placed in the route.
abstract interface class GoRouterWrapper {
  Widget wrappedRoute(BuildContext context);
}

extension GoRouteExtension on GoRoute {
  /// A route whose screen is wrapped through [GoRouterWrapper.wrappedRoute]
  /// when it implements it, and used as is otherwise.
  static GoRoute wrappedRoute({
    required String name,
    required String path,
    required Widget Function(BuildContext context, GoRouterState state)
    wrappedBuilder,
    List<RouteBase> routes = const <RouteBase>[],
  }) {
    return GoRoute(
      name: name,
      path: path,
      routes: routes,
      pageBuilder: (BuildContext context, GoRouterState state) {
        final Widget screen = wrappedBuilder(context, state);
        return NoTransitionPage(
          child: screen is GoRouterWrapper
              ? (screen as GoRouterWrapper).wrappedRoute(context)
              : screen,
        );
      },
    );
  }
}
