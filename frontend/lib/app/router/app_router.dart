import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'package:skill_battles/app/router/app_routes.dart';
import 'package:skill_battles/app/shell/app_shell.dart';
import 'package:skill_battles/core/presentation/overlay/app_overlay.dart';
import 'package:skill_battles/core/utils/extensions/route_extension.dart';
import 'package:skill_battles/core/utils/session/auth_session.dart';
import 'package:skill_battles/features/auth/presentation/screens/auth_screen.dart';
import 'package:skill_battles/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:skill_battles/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:skill_battles/features/battle/presentation/screens/battle_screen.dart';
import 'package:skill_battles/features/battle_result/presentation/screens/battle_result_screen.dart';
import 'package:skill_battles/features/friends/presentation/screens/friend_profile_screen.dart';
import 'package:skill_battles/features/friends/presentation/screens/friends_screen.dart';
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
///
/// The router does not listen to [session] itself: the app root re-runs
/// the redirect on every session change (see `SkillBattlesApp`).
Router createAppRouter({required AuthSession session, Key? key}) {
  return Router(
    key: key,
    redirect: (BuildContext context, RouteState state) =>
        _redirect(session, state),
    errorBuilder: (BuildContext context, RouteState state) =>
        const _NotFound(),
    routes: <RouteBase>[
      // Dialogs and snack bars live inside the router so their content can
      // navigate.
      ShellRoute(
        builder: (BuildContext context, RouteState state, Component child) =>
            AppOverlayHost(child: child),
        routes: <RouteBase>[
          wrappedRoute(
            name: AppRoutes.auth.name,
            path: AppRoutes.auth.path,
            wrappedBuilder: (_, _) => const AuthScreen(),
          ),
          wrappedRoute(
            name: AppRoutes.forgotPassword.name,
            path: AppRoutes.forgotPassword.path,
            wrappedBuilder: (_, _) => const ForgotPasswordScreen(),
          ),
          wrappedRoute(
            name: AppRoutes.resetPassword.name,
            path: AppRoutes.resetPassword.path,
            wrappedBuilder: (_, RouteState state) => ResetPasswordScreen(
              token: state.queryParams[AppRoutes.tokenParam],
            ),
          ),
          wrappedRoute(
            name: AppRoutes.battle.name,
            path: AppRoutes.battle.path,
            wrappedBuilder: (_, RouteState state) => BattleScreen(
              battleId: state.params[AppRoutes.battleIdParam]!,
            ),
          ),
          ShellRoute(
            builder:
                (BuildContext context, RouteState state, Component child) {
                  final String? routeName = _routeNameOf(state);
                  return AppShell(
                    activeTab: AppShell.tabFor(routeName),
                    routeName: routeName,
                    pathParameters: state.params,
                    child: child,
                  );
                },
            routes: <RouteBase>[
              wrappedRoute(
                name: AppRoutes.home.name,
                path: AppRoutes.home.path,
                wrappedBuilder: (_, _) => const HomeScreen(),
              ),
              wrappedRoute(
                name: AppRoutes.rankedSearch.name,
                path: AppRoutes.rankedSearch.path,
                wrappedBuilder: (_, RouteState state) => RankedSearchScreen(
                  disciplineCode: _query(state, AppRoutes.disciplineParam),
                  entryId: _query(state, AppRoutes.entryParam),
                ),
              ),
              wrappedRoute(
                name: AppRoutes.privateDuel.name,
                path: AppRoutes.privateDuel.path,
                wrappedBuilder: (_, RouteState state) => PrivateDuelScreen(
                  disciplineCode: _query(state, AppRoutes.disciplineParam),
                  duelId: _query(state, AppRoutes.duelParam),
                ),
              ),
              wrappedRoute(
                name: AppRoutes.battleResult.name,
                path: AppRoutes.battleResult.path,
                wrappedBuilder: (_, RouteState state) => BattleResultScreen(
                  battleId: state.params[AppRoutes.battleIdParam]!,
                ),
              ),
              wrappedRoute(
                name: AppRoutes.profile.name,
                path: AppRoutes.profile.path,
                wrappedBuilder: (_, _) => const ProfileScreen(),
              ),
              wrappedRoute(
                name: AppRoutes.editProfile.name,
                path: AppRoutes.editProfile.path,
                wrappedBuilder: (_, _) => const EditProfileScreen(),
              ),
              wrappedRoute(
                name: AppRoutes.leaderboard.name,
                path: AppRoutes.leaderboard.path,
                wrappedBuilder: (_, RouteState state) => LeaderboardScreen(
                  disciplineCode: _query(state, AppRoutes.disciplineParam),
                ),
              ),
              wrappedRoute(
                name: AppRoutes.history.name,
                path: AppRoutes.history.path,
                wrappedBuilder: (_, _) => const HistoryScreen(),
              ),
              wrappedRoute(
                name: AppRoutes.friends.name,
                path: AppRoutes.friends.path,
                wrappedBuilder: (_, _) => const FriendsScreen(),
              ),
              wrappedRoute(
                name: AppRoutes.friendProfile.name,
                path: AppRoutes.friendProfile.path,
                wrappedBuilder: (_, RouteState state) => FriendProfileScreen(
                  friendId: state.params[AppRoutes.friendIdParam]!,
                  relationshipId: state.extra is String
                      ? state.extra! as String
                      : null,
                ),
              ),
              wrappedRoute(
                name: AppRoutes.pro.name,
                path: AppRoutes.pro.path,
                wrappedBuilder: (_, _) => const ProScreen(),
              ),
              wrappedRoute(
                name: AppRoutes.billingReturn.name,
                path: AppRoutes.billingReturn.path,
                wrappedBuilder: (_, RouteState state) => BillingReturnScreen(
                  checkoutCancelled:
                      _query(state, AppRoutes.successParam) == 'false',
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

String? _redirect(AuthSession session, RouteState state) {
  final String path = Uri.parse(state.location).path;
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

/// Name of the matched leaf route ([RouteState.name] is empty in a shell).
String? _routeNameOf(RouteState state) {
  for (final AppRoutes route in AppRoutes.values) {
    if (route.path == state.fullpath) return route.name;
  }
  return null;
}

/// A non-empty query value, `null` otherwise.
String? _query(RouteState state, String key) {
  final String? value = state.queryParams[key];
  return value == null || value.isEmpty ? null : value;
}

/// An unknown address: back to the home page (which redirects to log-in
/// when signed out).
final class _NotFound extends StatefulComponent {
  const _NotFound();

  @override
  State<_NotFound> createState() => _NotFoundState();
}

final class _NotFoundState extends State<_NotFound> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      if (mounted) Router.of(context).replace(AppRoutes.home.path);
    });
  }

  @override
  Component build(BuildContext context) => const Component.empty();
}
