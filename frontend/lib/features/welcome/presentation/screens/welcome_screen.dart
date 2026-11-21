import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_compositions_scope.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/features_section.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/final_cta_section.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/how_it_works_section.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/leagues_section.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/welcome_facts_strip.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/welcome_footer.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/welcome_hero.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/welcome_navigation.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/welcome_top_bar.dart';

/// The public landing page (Paper: "52 Welcome — landing"): what a battle
/// is, the product's features, the league ladder and the ways in. Static:
/// no data requests, so no BLoC and no loading or error states.
///
/// It starts loading the sticker compositions of the battle feature (an
/// app-wide resource) for its decorative stickers.
final class WelcomeScreen extends StatefulComponent {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

final class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    if (kIsWeb) StickerCompositionsScope.maybeOf(context, listen: false)?.ensureLoaded();
  }

  @override
  Component build(BuildContext context) {
    return AppDesktopViewport(
      fullBleed: true,
      child: div(
        id: WelcomeAnchors.top,
        classes: 'welcome',
        attributes: const <String, String>{'tabindex': '-1'},
        const <Component>[
          WelcomeTopBar(),
          main_(<Component>[
            WelcomeHero(),
            WelcomeFactsStrip(),
            HowItWorksSection(),
            FeaturesSection(),
            LeaguesSection(),
            FinalCtaSection(),
          ]),
          WelcomeFooter(),
        ],
      ),
    );
  }
}
