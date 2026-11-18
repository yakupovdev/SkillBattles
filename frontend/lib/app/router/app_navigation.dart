import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'package:skill_battles/app/router/app_routes.dart';

/// Navigation with the `go_router` vocabulary of the Flutter app. Every
/// call adds a browser history entry (like `go` on the web).
extension AppNavigation on BuildContext {
  /// Opens [location] (a path with an optional query).
  void go(String location) => Router.of(this).push(location);

  /// Opens the route named [name] (an `AppRoutes.x.name`).
  void goNamed(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
  }) => Router.of(this).pushNamed(
    name,
    params: pathParameters,
    queryParams: queryParameters,
    extra: extra,
  );

  /// Replaces the current history entry with [location] (no back step),
  /// e.g. to drop a one-use token from the address bar.
  void replaceLocation(String location) => Router.of(this).replace(location);

  void goBattle(String battleId) => goNamed(
    AppRoutes.battle.name,
    pathParameters: <String, String>{AppRoutes.battleIdParam: battleId},
  );

  void goBattleResult(String battleId) => goNamed(
    AppRoutes.battleResult.name,
    pathParameters: <String, String>{AppRoutes.battleIdParam: battleId},
  );

  void goRankedSearch({String? disciplineCode, String? entryId}) => goNamed(
    AppRoutes.rankedSearch.name,
    queryParameters: <String, String>{
      AppRoutes.disciplineParam: ?disciplineCode,
      AppRoutes.entryParam: ?entryId,
    },
  );

  void goPrivateDuel({String? disciplineCode, String? duelId}) => goNamed(
    AppRoutes.privateDuel.name,
    queryParameters: <String, String>{
      AppRoutes.disciplineParam: ?disciplineCode,
      AppRoutes.duelParam: ?duelId,
    },
  );

  void goLeaderboard({String? disciplineCode}) => goNamed(
    AppRoutes.leaderboard.name,
    queryParameters: <String, String>{
      AppRoutes.disciplineParam: ?disciplineCode,
    },
  );

  void goHome() => goNamed(AppRoutes.home.name);

  void goPro() => goNamed(AppRoutes.pro.name);
}
