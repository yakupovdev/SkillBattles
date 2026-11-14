import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/skill_battles_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Real paths (no `#`), so server-configured return URLs such as
  // `/billing/return` and `/auth/reset?token=…` open the right screen.
  usePathUrlStrategy();
  final AppDependencies dependencies = await AppDependencies.init();
  runApp(
    AppDependenciesProvider(
      dependencies: dependencies,
      child: SkillBattlesApp(router: dependencies.getDep<GoRouter>()),
    ),
  );
}
