import '../../helpers/app_test_harness.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/router/app_routes.dart';

/// Desktop platforms default to compact visual density, which would shrink
/// every input by 8 px. The artboards are drawn at standard density.
void main() {
  final TargetPlatformVariant desktop = TargetPlatformVariant.only(
    TargetPlatform.macOS,
  );

  testWidgets('a text field box is 48 px high on desktop', (
    WidgetTester tester,
  ) async {
    final AppDependencies deps = await pumpApp(
      tester,
      location: AppRoutes.forgotPassword.path,
    );

    expect(tester.getSize(find.byType(InputDecorator).first).height, 48);
    await finishApp(tester, deps);
  }, variant: desktop);

  testWidgets('the home code tile is 88 px high on desktop', (
    WidgetTester tester,
  ) async {
    final AppDependencies deps = await pumpApp(tester, signedIn: true);
    await settle(tester, 8);

    final Finder tile = find
        .ancestor(
          of: find.text('Have a code?'),
          matching: find.byType(AnimatedContainer),
        )
        .first;
    expect(tester.getSize(tile).height, 88);
    await finishApp(tester, deps);
  }, variant: desktop);
}
