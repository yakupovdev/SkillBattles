import 'helpers/app_test_harness.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/features/auth/presentation/screens/auth_screen.dart';
import 'package:skill_battles/features/home/presentation/screens/home_screen.dart';

void main() {
  testWidgets('a signed-out start is redirected to the auth screen', (
    WidgetTester tester,
  ) async {
    final AppDependencies deps = await pumpApp(tester);

    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.text('When were you born?'), findsOneWidget);

    await finishApp(tester, deps);
  });

  testWidgets('a signed-in start opens home with the catalogue', (
    WidgetTester tester,
  ) async {
    final AppDependencies deps = await pumpApp(tester, signedIn: true);
    await settle(tester, 8);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('SAT Math'), findsWidgets);
    expect(find.text('SAT Reading & Writing'), findsWidgets);
    expect(
      find.textContaining('free ranked matches left today'),
      findsOneWidget,
    );

    await finishApp(tester, deps);
  });
}
