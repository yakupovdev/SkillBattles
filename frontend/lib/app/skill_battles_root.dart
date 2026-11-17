import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/skill_battles_app.dart';

/// The hydrated root of the app (Jaspr server mode).
///
/// The server renders the document and an empty placeholder here. The app
/// itself starts only in the browser: the session lives in `localStorage`
/// (tokens never go to cookies), and the realtime connection, KaTeX and
/// lottie-web are browser-only, so the server cannot render a signed-in page.
@client
final class SkillBattlesRoot extends StatefulComponent {
  const SkillBattlesRoot({super.key});

  @override
  State<SkillBattlesRoot> createState() => _SkillBattlesRootState();
}

final class _SkillBattlesRootState extends State<SkillBattlesRoot> {
  AppDependencies? _dependencies;

  @override
  void initState() {
    super.initState();
    // The first client build matches the server's placeholder, so hydration
    // succeeds; the app mounts once the dependencies are ready.
    if (kIsWeb) {
      AppDependencies.init().then((AppDependencies dependencies) {
        if (!mounted) {
          dependencies.dispose();
          return;
        }
        setState(() => _dependencies = dependencies);
      });
    }
  }

  @override
  void dispose() {
    _dependencies?.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final AppDependencies? dependencies = _dependencies;
    if (dependencies == null) return const Component.empty();
    return AppDependenciesProvider(
      dependencies: dependencies,
      child: const SkillBattlesApp(),
    );
  }
}
