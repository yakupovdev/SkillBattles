import '../../helpers/app_test_harness.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/router/app_routes.dart';
import 'package:skill_battles/dev/dev_scenario.dart';
import 'package:skill_battles/dev/mock_backend.dart';
import 'package:skill_battles/features/battle/presentation/screens/battle_screen.dart';
import 'package:skill_battles/features/matchmaking/presentation/screens/ranked_search_screen.dart';

/// End to end through the real screens, BLoCs, repositories and remotes,
/// over the development mock backend.
void main() {
  testWidgets(
    'Free ranked match: search, ready, answer and a reveal without the '
    'correct option',
    (WidgetTester tester) async {
      final AppDependencies deps = await pumpApp(tester, signedIn: true);
      deps.getDep<MockBackend>().scenario.opponent = DevOpponent.alwaysWrong;
      await settle(tester, 8);

      await tester.tap(find.text('Find ranked match'));
      await settle(tester);
      expect(find.byType(RankedSearchScreen), findsOneWidget);

      // The mock finds an opponent after ~4.5 s.
      await tester.pump(const Duration(seconds: 5));
      await settle(tester, 6);
      expect(find.byType(BattleScreen), findsOneWidget);
      expect(find.text('Ready check'), findsOneWidget);
      expect(find.textContaining('free ranked matches'), findsOneWidget);

      await tester.tap(find.text("I'm ready"));
      await settle(tester, 8);
      // Countdown 3 s, then the first question.
      await tester.pump(const Duration(seconds: 3));
      await settle(tester, 4);
      expect(find.text('Submit answer'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(RegExp('^Answer A')).first);
      await settle(tester, 2);
      await tester.tap(find.text('Submit answer'));
      await settle(tester, 4);
      expect(find.textContaining('Answer locked in'), findsOneWidget);

      // The bot answers within 10 s, then the round reveals for 5 s.
      final Finder freeNote = find.textContaining(
        'The correct option stays hidden on Free.',
        findRichText: true,
      );
      for (int i = 0; i < 24 && freeNote.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(freeNote, findsOneWidget);
      expect(
        find.textContaining('Correct answer:', findRichText: true),
        findsNothing,
      );

      await finishApp(tester, deps);
    },
  );

  testWidgets('the daily limit opens the limit dialog that points to Pro', (
    WidgetTester tester,
  ) async {
    final AppDependencies deps = await pumpApp(tester, signedIn: true);
    await tester.runAsync(() async {
      deps.getDep<MockBackend>().setDailyLimitReached(true);
    });
    deps.getDep<GoRouter>().goNamed(AppRoutes.profile.name);
    await settle(tester, 6);
    deps.getDep<GoRouter>().goNamed(AppRoutes.home.name);
    await settle(tester, 8);

    expect(
      find.textContaining('free ranked matches left today', findRichText: true),
      findsOneWidget,
    );

    await tester.tap(find.text('Find ranked match'));
    await settle(tester, 4);

    expect(find.textContaining('ranked matches for today'), findsOneWidget);
    expect(find.text('Unlimited ranked with Pro'), findsOneWidget);
    expect(deps.getDep<GoRouter>().state.name, AppRoutes.home.name);

    await tester.tap(find.text('Not now'));
    await settle(tester, 4);
    expect(find.textContaining('ranked matches for today'), findsNothing);

    await finishApp(tester, deps);
  });
}
