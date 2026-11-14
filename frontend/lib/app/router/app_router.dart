import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/router/app_routes.dart';
import 'package:skill_battles/app/shell/app_shell.dart';
import 'package:skill_battles/core/utils/extensions/go_router_extension.dart';
import 'package:skill_battles/core/utils/session/auth_session.dart';
import 'package:skill_battles/features/auth/presentation/screens/auth_screen.dart';
import 'package:skill_battles/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:skill_battles/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:skill_battles/features/battle/presentation/screens/battle_screen.dart';
import 'package:skill_battles/features/battle_result/presentation/screens/battle_result_screen.dart';
import 'package:skill_battles/features/history/presentation/screens/history_screen.dart';
import 'package:skill_battles/features/home/presentation/screens/home_screen.dart';
import 'package:skill_battles/features/leaderboard/presentation/screens/leaderboard_screen.dart';
import 'package:skill_battles/features/matchmaking/presentation/screens/ranked_search_screen.dart';
import 'package:skill_battles/features/private_duel/presentation/screens/private_duel_screen.dart';
import 'package:skill_battles/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:skill_battles/features/profile/presentation/screens/profile_screen.dart';
import 'package:skill_battles/features/subscription/presentation/screens/billing_return_screen.dart';
import 'package:skill_battles/features/subscription/presentation/screens/pro_screen.dart';

/// Builds the app router. Signed-out users only reach the auth routes; a
/// signed-in user never sees the log-in screen. The live battle is
/// full-screen; everything else sits in [AppShell].
GoRouter createAppRouter({
  required AuthSession session,
  String? initialLocation,
}) {
  return GoRouter(
    initialLocation: initialLocation ?? AppRoutes.home.path,
    refreshListenable: session,
    redirect: (BuildContext context, GoRouterState state) =>
        _redirect(session, state),
    routes: <RouteBase>[
      GoRouteExtension.wrappedRoute(
        name: AppRoutes.auth.name,
        path: AppRoutes.auth.path,
        wrappedBuilder: (_, _) => const AuthScreen(),
      ),
      GoRouteExtension.wrappedRoute(
        name: AppRoutes.forgotPassword.name,
        path: AppRoutes.forgotPassword.path,
        wrappedBuilder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRouteExtension.wrappedRoute(
        name: AppRoutes.resetPassword.name,
        path: AppRoutes.resetPassword.path,
        wrappedBuilder: (_, GoRouterState state) => ResetPasswordScreen(
          token: state.uri.queryParameters[AppRoutes.tokenParam],
        ),
      ),
      GoRouteExtension.wrappedRoute(
        name: AppRoutes.battle.name,
        path: AppRoutes.battle.path,
        wrappedBuilder: (_, GoRouterState state) => BattleScreen(
          battleId: state.pathParameters[AppRoutes.battleIdParam]!,
        ),
      ),
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) =>
            AppShell(
              activeTab: AppShell.tabFor(state.topRoute?.name),
              child: child,
            ),
        routes: <RouteBase>[
          GoRouteExtension.wrappedRoute(
            name: AppRoutes.home.name,
            path: AppRoutes.home.path,
            wrappedBuilder: (_, _) => const HomeScreen(),
          ),
          GoRouteExtension.wrappedRoute(
            name: AppRoutes.rankedSearch.name,
            path: AppRoutes.rankedSearch.path,
            wrappedBuilder: (_, GoRouterState state) => RankedSearchScreen(
              disciplineCode: _query(state, AppRoutes.disciplineParam),
              entryId: _query(state, AppRoutes.entryParam),
            ),
          ),
          GoRouteExtension.wrappedRoute(
            name: AppRoutes.privateDuel.name,
            path: AppRoutes.privateDuel.path,
            wrappedBuilder: (_, GoRouterState state) => PrivateDuelScreen(
              disciplineCode: _query(state, AppRoutes.disciplineParam),
              duelId: _query(state, AppRoutes.duelParam),
            ),
          ),
          GoRouteExtension.wrappedRoute(
            name: AppRoutes.battleResult.name,
            path: AppRoutes.battleResult.path,
            wrappedBuilder: (_, GoRouterState state) => BattleResultScreen(
              battleId: state.pathParameters[AppRoutes.battleIdParam]!,
            ),
          ),
          GoRouteExtension.wrappedRoute(
            name: AppRoutes.profile.name,
            path: AppRoutes.profile.path,
            wrappedBuilder: (_, _) => const ProfileScreen(),
          ),
          GoRouteExtension.wrappedRoute(
            name: AppRoutes.editProfile.name,
            path: AppRoutes.editProfile.path,
            wrappedBuilder: (_, _) => const EditProfileScreen(),
          ),
          GoRouteExtension.wrappedRoute(
            name: AppRoutes.leaderboard.name,
            path: AppRoutes.leaderboard.path,
            wrappedBuilder: (_, GoRouterState state) => LeaderboardScreen(
              disciplineCode: _query(state, AppRoutes.disciplineParam),
            ),
          ),
          GoRouteExtension.wrappedRoute(
            name: AppRoutes.history.name,
            path: AppRoutes.history.path,
            wrappedBuilder: (_, _) => const HistoryScreen(),
          ),
          GoRouteExtension.wrappedRoute(
            name: AppRoutes.pro.name,
            path: AppRoutes.pro.path,
            wrappedBuilder: (_, _) => const ProScreen(),
          ),
          GoRouteExtension.wrappedRoute(
            name: AppRoutes.billingReturn.name,
            path: AppRoutes.billingReturn.path,
            wrappedBuilder: (_, GoRouterState state) => BillingReturnScreen(
              checkoutCancelled:
                  _query(state, AppRoutes.successParam) == 'false',
            ),
          ),
        ],
      ),
    ],
  );
}

String? _redirect(AuthSession session, GoRouterState state) {
  final String path = state.matchedLocation;
  final bool isPublic = AppRoutes.public.any(
    (AppRoutes route) => route.path == path,
  );
  if (!session.isSignedIn) return isPublic ? null : AppRoutes.auth.path;
  // A reset link still works while signed in (it signs the device out).
  if (path == AppRoutes.auth.path || path == AppRoutes.forgotPassword.path) {
    return AppRoutes.home.path;
  }
  return null;
}

/// A non-empty query value, `null` otherwise.
String? _query(GoRouterState state, String key) {
  final String? value = state.uri.queryParameters[key];
  return value == null || value.isEmpty ? null : value;
}
