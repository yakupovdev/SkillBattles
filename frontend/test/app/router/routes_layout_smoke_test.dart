import '../../helpers/app_test_harness.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/router/app_routes.dart';

void main() {
  const Map<String, Size> windows = <String, Size>{
    '1440x900': desktopArtboard,
    '1024x700': Size(1024, 700),
  };
  // Routes with a path parameter need a real battle; they are covered by
  // the flow tests.
  final List<AppRoutes> routes = AppRoutes.values
      .where((AppRoutes route) => !route.path.contains(':'))
      .toList();

  for (final MapEntry<String, Size> window in windows.entries) {
    for (final AppRoutes route in routes) {
      testWidgets('${route.name} lays out at ${window.key} without errors', (
        WidgetTester tester,
      ) async {
        final AppDependencies deps = await pumpApp(
          tester,
          location: route.path,
          size: window.value,
          signedIn: !AppRoutes.public.contains(route),
        );
        await settle(tester, 8);

        expect(tester.takeException(), isNull);
        await finishApp(tester, deps);
      });
    }
  }
}
