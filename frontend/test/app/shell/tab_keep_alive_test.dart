import 'package:test/test.dart';

import 'package:skill_battles/app/router/app_routes.dart';
import 'package:skill_battles/app/shell/tab_keep_alive.dart';

void main() {
  group('TabKeepAlive.reusesKept', () {
    test('reuses the kept tab for the same location', () {
      expect(
        TabKeepAlive.reusesKept(
          keptLocation: '/leaderboard?discipline=SAT_MATH',
          location: '/leaderboard?discipline=SAT_MATH',
        ),
        isTrue,
      );
    });

    test('reuses the kept tab for the bare tab path of a tab click', () {
      expect(
        TabKeepAlive.reusesKept(
          keptLocation: '/leaderboard?discipline=SAT_MATH',
          location: '/leaderboard',
        ),
        isTrue,
      );
    });

    test('builds a fresh page for a deep link with another query', () {
      expect(
        TabKeepAlive.reusesKept(
          keptLocation: '/leaderboard',
          location: '/leaderboard?discipline=SAT_MATH',
        ),
        isFalse,
      );
      expect(
        TabKeepAlive.reusesKept(
          keptLocation: '/leaderboard?discipline=SAT_MATH',
          location: '/leaderboard?discipline=SAT_VERBAL',
        ),
        isFalse,
      );
    });
  });

  test('AppRoutes.tabRoots holds only routes without path parameters', () {
    for (final AppRoutes route in AppRoutes.tabRoots) {
      expect(route.path, isNot(contains(':')), reason: route.name);
    }
  });
}
