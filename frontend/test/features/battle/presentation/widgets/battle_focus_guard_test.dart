import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_theme.dart';
import 'package:skill_battles/features/battle/presentation/widgets/battle_focus_guard.dart';

const String _question = 'What is 2 + 2?';

Widget _app({required bool enabled, String roundId = 'r1'}) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: BattleFocusGuard(
      enabled: enabled,
      roundId: roundId,
      child: const SizedBox(height: 300, child: Text(_question)),
    ),
  ),
);

Finder get _blurred =>
    find.byWidgetPredicate((Widget w) => w is ImageFiltered && w.enabled);

final Finder _cover = find.text('Battle hidden');
final Finder _warning = find.textContaining('You left the battle tab.');

Future<void> _setLifecycle(WidgetTester tester, AppLifecycleState state) async {
  tester.binding.handleAppLifecycleStateChanged(state);
  await tester.pump();
}

/// The tab is switched away and back: inactive → hidden → inactive → resumed.
Future<void> _leaveAndReturn(WidgetTester tester) async {
  await _setLifecycle(tester, AppLifecycleState.inactive);
  await _setLifecycle(tester, AppLifecycleState.hidden);
  await _setLifecycle(tester, AppLifecycleState.inactive);
  await _setLifecycle(tester, AppLifecycleState.resumed);
}

void main() {
  tearDown(() {
    TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
  });

  group('BattleFocusGuard', () {
    testWidgets('in front: the round is shown as is, with no warning', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_app(enabled: true));

      expect(find.text(_question), findsOneWidget);
      expect(_blurred, findsNothing);
      expect(_cover, findsNothing);
      expect(_warning, findsNothing);
    });

    testWidgets('a window losing focus blurs the round and hides it from '
        'semantics until it is back', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.pumpWidget(_app(enabled: true));

      await _setLifecycle(tester, AppLifecycleState.inactive);
      expect(_blurred, findsOneWidget);
      expect(_cover, findsOneWidget);
      expect(find.semantics.byLabel(_question), findsNothing);

      await _setLifecycle(tester, AppLifecycleState.hidden);
      expect(_blurred, findsOneWidget);

      await _setLifecycle(tester, AppLifecycleState.inactive);
      await _setLifecycle(tester, AppLifecycleState.resumed);
      expect(_blurred, findsNothing);
      expect(_cover, findsNothing);
      expect(find.semantics.byLabel(_question), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('coming back shows the warning; the count appears from the '
        'second leave', (WidgetTester tester) async {
      await tester.pumpWidget(_app(enabled: true));

      await _leaveAndReturn(tester);
      expect(_warning, findsOneWidget);
      expect(find.textContaining('times this match'), findsNothing);

      await _leaveAndReturn(tester);
      expect(find.textContaining('(2 times this match)'), findsOneWidget);
    });

    testWidgets('"Got it" hides the warning', (WidgetTester tester) async {
      await tester.pumpWidget(_app(enabled: true));
      await _leaveAndReturn(tester);

      await tester.tap(find.text('Got it'));
      await tester.pump();

      expect(_warning, findsNothing);
    });

    testWidgets('the next round clears the warning but keeps the count', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_app(enabled: true));
      await _leaveAndReturn(tester);

      await tester.pumpWidget(_app(enabled: true, roundId: 'r2'));
      expect(_warning, findsNothing);

      await _leaveAndReturn(tester);
      expect(find.textContaining('(2 times this match)'), findsOneWidget);
    });

    testWidgets('disabled: nothing is blurred and no leave is counted', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_app(enabled: false));

      await _setLifecycle(tester, AppLifecycleState.inactive);
      expect(_blurred, findsNothing);
      expect(_cover, findsNothing);

      await _setLifecycle(tester, AppLifecycleState.resumed);
      expect(_warning, findsNothing);
    });
  });
}
