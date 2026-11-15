import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/config/app_config.dart';
import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/skill_battles_app.dart';
import 'package:skill_battles/features/auth/domain/entity/login_params_entity.dart';
import 'package:skill_battles/features/auth/domain/usecases/login_usecase.dart';

/// Desktop artboard size the screens are laid out for.
const Size desktopArtboard = Size(1440, 900);

/// Window used to check the horizontal-scroll fallback of the viewport.
const Size narrowDesktop = Size(1280, 760);

const AppConfig mockConfig = AppConfig(apiBaseUrl: '', eventsUrl: '');

/// Pumps the real app over the real router and DI, backed by the in-app
/// development mock backend (no network). Call [finishApp] at the end.
Future<AppDependencies> pumpApp(
  WidgetTester tester, {
  String? location,
  Size size = desktopArtboard,
  bool signedIn = false,
  bool isPro = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  late final AppDependencies dependencies;
  await tester.runAsync(() async {
    dependencies = await AppDependencies.init(config: mockConfig);
    if (signedIn) {
      await dependencies.getDep<LoginUsecase>()(
        const LoginParamsEntity(
          email: 'tester@example.com',
          password: 'Password1!',
        ),
      );
    }
  });
  final GoRouter router = dependencies.getDep<GoRouter>();
  if (location != null) router.go(location);

  await tester.pumpWidget(
    AppDependenciesProvider(
      dependencies: dependencies,
      child: SkillBattlesApp(router: router),
    ),
  );
  await settle(tester);
  return dependencies;
}

/// Unmounts the app, lets every pending mock timer fire and disposes DI.
Future<void> finishApp(
  WidgetTester tester,
  AppDependencies dependencies,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(minutes: 5));
  await tester.runAsync(dependencies.dispose);
}

/// Advances the frame clock far enough for the mock latency and a route
/// transition. `pumpAndSettle` is not used: skeleton shimmers and countdown
/// timers schedule frames forever.
Future<void> settle(WidgetTester tester, [int steps = 4]) async {
  for (int i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// Name of the route the router is showing.
String? currentRouteName(GoRouter router) => router.state.name;

/// Moves keyboard focus to the first focusable inside [target], the way a
/// Tab press would land on it, so Enter and Space can be sent next.
Future<void> focusWithin(WidgetTester tester, Finder target) async {
  final Finder focusable = find.descendant(
    of: target,
    matching: find.byType(Focus),
  );
  final Finder inside = find.descendant(
    of: focusable.first,
    matching: find.byType(GestureDetector),
  );
  Focus.of(tester.element(inside.first)).requestFocus();
  await tester.pump();
}
