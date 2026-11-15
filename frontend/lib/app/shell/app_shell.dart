import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skill_battles/app/notifications/app_notifications_overlay.dart';
import 'package:skill_battles/app/router/app_routes.dart';
import 'package:skill_battles/core/presentation/widgets/app_top_bar.dart';
import 'package:skill_battles/features/account/presentation/bloc/account_bloc/account_bloc.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_compositions_scope.dart';

/// Page frame of every signed-in screen except the live battle: the top bar
/// above the routed page, with the global notifications overlay on top of
/// the page (never over the bar).
final class AppShell extends StatelessWidget {
  const AppShell({
    required this.activeTab,
    required this.routeName,
    required this.pathParameters,
    required this.child,
    super.key,
  });

  final AppNavTab? activeTab;

  /// Name of the current route, for the overlay's same-battle filter.
  final String? routeName;
  final Map<String, String> pathParameters;
  final Widget child;

  /// Tab highlighted for the route [name] (a `GoRoute.name`).
  static AppNavTab? tabFor(String? name) {
    if (name == AppRoutes.profile.name) return AppNavTab.stats;
    if (name == AppRoutes.history.name) return AppNavTab.history;
    if (name == AppRoutes.leaderboard.name) return AppNavTab.leaderboard;
    if (name == AppRoutes.friends.name ||
        name == AppRoutes.friendProfile.name) {
      return AppNavTab.friends;
    }
    if (name == AppRoutes.home.name ||
        name == AppRoutes.rankedSearch.name ||
        name == AppRoutes.privateDuel.name ||
        name == AppRoutes.battleResult.name) {
      return AppNavTab.play;
    }
    return null;
  }

  void _onAccountAction(BuildContext context, AppAccountAction action) {
    switch (action) {
      case AppAccountAction.editProfile:
        context.goNamed(AppRoutes.editProfile.name);
      case AppAccountAction.subscription:
        context.goNamed(AppRoutes.pro.name);
      case AppAccountAction.logOut:
        context.read<AccountBloc>().add(const AccountLogoutRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          BlocBuilder<AccountBloc, AccountState>(
            buildWhen: (AccountState previous, AccountState current) =>
                previous.account?.user != current.account?.user ||
                previous.isPro != current.isPro,
            builder: (BuildContext context, AccountState state) => AppTopBar(
              activeTab: activeTab,
              nickname: state.account?.user.nickname,
              isPro: state.isPro,
              onLogoPressed: () => context.goNamed(AppRoutes.home.name),
              onProPressed: () => context.goNamed(AppRoutes.pro.name),
              onAccountAction: (AppAccountAction action) =>
                  _onAccountAction(context, action),
              onTabSelected: (AppNavTab tab) => context.goNamed(
                switch (tab) {
                  AppNavTab.play => AppRoutes.home,
                  AppNavTab.leaderboard => AppRoutes.leaderboard,
                  AppNavTab.stats => AppRoutes.profile,
                  AppNavTab.history => AppRoutes.history,
                  AppNavTab.friends => AppRoutes.friends,
                }.name,
              ),
            ),
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                child,
                const StickerCompositionsPreload(),
                AppNotificationsOverlay(
                  routeName: routeName,
                  pathParameters: pathParameters,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
