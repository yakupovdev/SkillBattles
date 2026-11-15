import 'package:flutter_test/flutter_test.dart';

import 'package:skill_battles/features/auth/presentation/screens/auth_screen.dart';
import 'package:skill_battles/features/home/presentation/screens/home_screen.dart';

import 'helpers/router_harness.dart';

void main() {
  testWidgets('a signed-out start is redirected to the auth screen', (
    WidgetTester tester,
  ) async {
    final RouterHarness harness = await RouterHarness.create();
    addTearDown(() => harness.dispose(tester));
    await harness.pump(tester);

    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    await tester.tap(find.text('Create account'));
    await pumpFrames(tester);
    expect(
      find.text('When were you born?', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('a signed-in start opens home with the catalogue', (
    WidgetTester tester,
  ) async {
    final RouterHarness harness = await RouterHarness.create(signedIn: true);
    addTearDown(() => harness.dispose(tester));
    await harness.pump(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('SAT Math'), findsWidgets);
    expect(find.text('SAT Reading & Writing'), findsWidgets);
    expect(
      find.textContaining('free ranked matches left today', findRichText: true),
      findsOneWidget,
    );
  });
}
