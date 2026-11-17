import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

/// A screen that wraps itself in the providers it needs (for example a
/// `BlocSignalProvider` built from use cases) before it is placed in the
/// route.
abstract interface class RouteWrapper {
  Component wrappedRoute(BuildContext context);
}

/// A route whose screen is wrapped through [RouteWrapper.wrappedRoute] when
/// it implements it, and used as is otherwise.
Route wrappedRoute({
  required String name,
  required String path,
  required Component Function(BuildContext context, RouteState state)
  wrappedBuilder,
  String title = 'SkillBattles',
}) {
  return Route(
    name: name,
    path: path,
    title: title,
    builder: (BuildContext context, RouteState state) {
      final Component screen = wrappedBuilder(context, state);
      return screen is RouteWrapper
          ? (screen as RouteWrapper).wrappedRoute(context)
          : screen;
    },
  );
}
