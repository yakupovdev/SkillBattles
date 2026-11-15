import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/notifications/app_notifications_overlay.dart';
import 'package:skill_battles/app/router/app_routes.dart';
import 'package:skill_battles/app/theme/app_theme.dart';
import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/battle_result/domain/entity/rematch_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/rematch_status.dart';
import 'package:skill_battles/features/notifications/presentation/bloc/notification_bloc/notification_bloc.dart';

import '../../helpers/notification_fakes.dart';

final class _Page extends StatelessWidget {
  const _Page(this.state);

  final GoRouterState state;

  @override
  Widget build(BuildContext context) =>
      Center(child: Text('page:${state.name}'));
}

/// Like `AppShell`: one overlay above the routed page, kept across routes.
final class _Shell extends StatelessWidget {
  const _Shell({required this.state, required this.child});

  final GoRouterState state;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          child,
          AppNotificationsOverlay(
            routeName: state.topRoute?.name,
            pathParameters: state.pathParameters,
          ),
        ],
      ),
    );
  }
}

Future<void> _pump(WidgetTester tester, [Duration by = Duration.zero]) async {
  await tester.pump(by);
  for (int i = 0; i < 6; i++) {
    await tester.pump();
  }
}

Finder _richText(String fragment) => find.byWidgetPredicate(
  (Widget w) => w is RichText && w.text.toPlainText().contains(fragment),
);

final class _Setup {
  _Setup(this.fixture, this.router);

  final NotificationFixture fixture;
  final GoRouter router;

  Future<void> push(WidgetTester tester, RematchEntity entity) async {
    fixture.results.rematches.add(entity);
    await _pump(tester);
  }
}

Future<_Setup> _setUp(WidgetTester tester, {String? location}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final NotificationFixture fixture = NotificationFixture();
  addTearDown(fixture.dispose);
  final GoRouter router = GoRouter(
    initialLocation: location ?? AppRoutes.home.path,
    routes: <RouteBase>[
      // As in production: the live battle is outside the shell, so the
      // overlay is not mounted there.
      GoRoute(
        path: AppRoutes.battle.path,
        name: AppRoutes.battle.name,
        builder: (BuildContext context, GoRouterState state) => _Page(state),
      ),
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) =>
            _Shell(state: state, child: child),
        routes: <GoRoute>[
          GoRoute(
            path: AppRoutes.home.path,
            name: AppRoutes.home.name,
            builder: (BuildContext context, GoRouterState state) =>
                _Page(state),
          ),
          GoRoute(
            path: AppRoutes.battleResult.path,
            name: AppRoutes.battleResult.name,
            builder: (BuildContext context, GoRouterState state) =>
                _Page(state),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    BlocProvider<NotificationBloc>.value(
      value: fixture.bloc,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  fixture.bloc.add(const NotificationStarted());
  await _pump(tester);
  return _Setup(fixture, router);
}

void main() {
  group('AppNotificationsOverlay', () {
    testWidgets('shows an incoming request while on home (the reported bug)', (
      WidgetTester tester,
    ) async {
      final _Setup s = await _setUp(tester);

      expect(find.text('Rematch request'), findsNothing);
      await s.push(tester, rematch('b1'));

      expect(find.text('Rematch request'), findsOneWidget);
      expect(_richText('Rival'), findsWidgets);
      expect(_richText('wants a rematch in Math.'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });

    testWidgets('hides the card on the result screen of that battle only', (
      WidgetTester tester,
    ) async {
      final _Setup s = await _setUp(
        tester,
        location: AppRoutes.battleResult.path.replaceFirst(':battleId', 'b1'),
      );

      await s.push(tester, rematch('b1'));
      expect(find.text('page:${AppRoutes.battleResult.name}'), findsOneWidget);
      expect(find.text('Rematch request'), findsNothing);

      // Another battle's request is still shown there.
      await s.push(tester, rematch('b2'));
      expect(find.text('Rematch request'), findsOneWidget);

      s.router.goNamed(AppRoutes.home.name);
      await _pump(tester, const Duration(seconds: 1));
      expect(find.text('Rematch request'), findsNWidgets(2));
    });

    testWidgets('Accept and Decline taps reach the use cases', (
      WidgetTester tester,
    ) async {
      final _Setup s = await _setUp(tester);
      s.fixture.results.onRequest = (String id) async => Right(
        rematch(
          id,
          requestedBy: <String>[testOpponentId, testMeId],
          version: 2,
        ),
      );
      await s.push(tester, rematch('b1'));

      await tester.tap(find.text('Accept'));
      await _pump(tester);
      expect(s.fixture.results.requestCalls, <String>['b1']);

      await s.push(tester, rematch('b2'));
      // b1 is waiting as our own now; only b2 has Decline enabled.
      await tester.tap(find.text('Decline'));
      await _pump(tester);
      expect(s.fixture.results.cancelCalls, <String>['b2']);
    });

    testWidgets('shows at most three cards, soonest deadline first', (
      WidgetTester tester,
    ) async {
      final _Setup s = await _setUp(tester);
      for (final (String, int) r in <(String, int)>[
        ('late', 55),
        ('mid', 40),
        ('soon', 20),
        ('first', 10),
      ]) {
        await s.push(
          tester,
          rematch(r.$1, expiresAt: testNow.add(Duration(seconds: r.$2))),
        );
      }

      expect(find.text('Rematch request'), findsNWidgets(3));
      expect(find.byKey(const ValueKey<String>('rematch:late')), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('rematch:first')),
        findsOneWidget,
      );
      final double firstTop = tester
          .getTopLeft(find.byKey(const ValueKey<String>('rematch:first')))
          .dy;
      final double midTop = tester
          .getTopLeft(find.byKey(const ValueKey<String>('rematch:mid')))
          .dy;
      expect(firstTop, lessThan(midTop));
    });

    testWidgets('the pill appears after hiding and restores the card', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final _Setup s = await _setUp(tester);
      await s.push(tester, rematch('b1'));

      await tester.tap(find.bySemanticsLabel('Hide notification'));
      await _pump(tester);

      expect(find.text('Rematch request'), findsNothing);
      expect(find.text('1 pending rematch'), findsOneWidget);

      await tester.tap(find.text('1 pending rematch'));
      await _pump(tester);

      expect(find.text('Rematch request'), findsOneWidget);
      expect(find.text('1 pending rematch'), findsNothing);
      handle.dispose();
    });

    testWidgets('a notice shows a toast that hides after 4 seconds', (
      WidgetTester tester,
    ) async {
      final _Setup s = await _setUp(tester);
      await s.push(tester, rematch('b1'));
      await s.push(
        tester,
        rematch('b1', status: RematchStatus.cancelled, version: 2),
      );

      expect(find.text('The rematch request was cancelled.'), findsOneWidget);
      expect(s.fixture.state.notices, isEmpty);

      await _pump(tester, const Duration(seconds: 3));
      expect(find.text('The rematch request was cancelled.'), findsOneWidget);
      await _pump(tester, const Duration(seconds: 1));
      expect(find.text('The rematch request was cancelled.'), findsNothing);
    });

    testWidgets('a notice of the open result screen gives no toast', (
      WidgetTester tester,
    ) async {
      final _Setup s = await _setUp(
        tester,
        location: AppRoutes.battleResult.path.replaceFirst(':battleId', 'b1'),
      );
      await s.push(tester, rematch('b1'));
      await s.push(
        tester,
        rematch('b1', status: RematchStatus.cancelled, version: 2),
      );

      expect(find.text('The rematch request was cancelled.'), findsNothing);
      expect(s.fixture.state.notices, isEmpty);
    });

    testWidgets('battleToOpen navigates to the battle and is consumed', (
      WidgetTester tester,
    ) async {
      final _Setup s = await _setUp(tester);
      await s.push(tester, rematch('b1'));

      await s.push(
        tester,
        rematch(
          'b1',
          status: RematchStatus.matched,
          version: 2,
          battleId: 'n1',
        ),
      );
      await _pump(tester, const Duration(milliseconds: 500));

      expect(find.text('page:${AppRoutes.battle.name}'), findsOneWidget);
      expect(s.router.state.pathParameters[AppRoutes.battleIdParam], 'n1');
      expect(s.fixture.state.battleToOpen, isNull);
    });

    testWidgets('on the source result screen it still opens the new battle', (
      WidgetTester tester,
    ) async {
      final _Setup s = await _setUp(
        tester,
        location: AppRoutes.battleResult.path.replaceFirst(':battleId', 'b1'),
      );

      await s.push(
        tester,
        rematch(
          'b1',
          status: RematchStatus.matched,
          version: 2,
          battleId: 'n1',
        ),
      );
      await _pump(tester, const Duration(milliseconds: 500));

      // The result screen may navigate too; the same location is a no-op.
      expect(find.text('page:${AppRoutes.battle.name}'), findsOneWidget);
      expect(s.router.state.pathParameters[AppRoutes.battleIdParam], 'n1');
      expect(s.fixture.state.battleToOpen, isNull);
    });

    testWidgets('what arrived during a battle is dropped on return to the '
        'shell', (WidgetTester tester) async {
      final _Setup s = await _setUp(tester);
      await s.push(tester, rematch('b1'));
      await s.push(tester, rematch('b2'));
      await s.push(
        tester,
        rematch('b2', status: RematchStatus.cancelled, version: 2),
      );
      await _pump(tester, const Duration(seconds: 5));

      // In a live battle: the shell and its overlay are gone.
      s.router.go(AppRoutes.battle.path.replaceFirst(':battleId', 'x1'));
      await _pump(tester, const Duration(milliseconds: 500));
      await _pump(tester, const Duration(milliseconds: 500));
      expect(find.byType(AppNotificationsOverlay), findsNothing);
      await s.push(
        tester,
        rematch(
          'b1',
          status: RematchStatus.matched,
          version: 2,
          battleId: 'n1',
        ),
      );
      expect(s.fixture.state.battleToOpen, 'n1');
      expect(s.fixture.state.notices, isNotEmpty);

      // Back in the shell, e.g. on the result of the battle just played.
      s.router.go(AppRoutes.home.path);
      await _pump(tester, const Duration(milliseconds: 500));

      expect(s.fixture.state.battleToOpen, isNull);
      expect(s.fixture.state.notices, isEmpty);
      expect(find.text('page:${AppRoutes.home.name}'), findsOneWidget);
      expect(
        find.text('Rematch accepted. Opening the ready check…'),
        findsNothing,
      );

      // A later notice shows only itself.
      await s.push(tester, rematch('b3'));
      await s.push(
        tester,
        rematch('b3', status: RematchStatus.cancelled, version: 2),
      );
      expect(find.text('The rematch request was cancelled.'), findsOneWidget);
      expect(
        find.text('Rematch accepted. Opening the ready check…'),
        findsNothing,
      );
    });

    testWidgets('the connection indicator needs a disconnect and a card', (
      WidgetTester tester,
    ) async {
      final _Setup s = await _setUp(tester);

      s.fixture.connection.changes.add(RealtimeStatus.disconnected);
      await _pump(tester);
      expect(find.text('Reconnecting…'), findsNothing);

      await s.push(tester, rematch('b1'));
      expect(find.text('Reconnecting…'), findsOneWidget);

      s.fixture.connection.changes.add(RealtimeStatus.connected);
      await _pump(tester);
      expect(find.text('Reconnecting…'), findsNothing);
    });

    testWidgets('a route change re-reads the activity', (
      WidgetTester tester,
    ) async {
      final _Setup s = await _setUp(tester);
      final int before = s.fixture.account.activityCalls;

      s.router.goNamed(
        AppRoutes.battleResult.name,
        pathParameters: <String, String>{AppRoutes.battleIdParam: 'x'},
      );
      await _pump(tester, const Duration(milliseconds: 500));

      expect(s.fixture.account.activityCalls, greaterThan(before));
    });
  });
}
