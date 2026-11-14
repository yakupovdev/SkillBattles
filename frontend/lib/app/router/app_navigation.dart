import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/router/app_routes.dart';

/// Typed navigation to routes with parameters.
extension AppNavigation on BuildContext {
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
