import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';

/// The amber-on-ink "TEST MODE" chip: Stripe runs with test cards only.
final class AppTestModeBadge extends StatelessComponent {
  const AppTestModeBadge({super.key});

  @override
  Component build(BuildContext context) {
    return const span(classes: 'app-test-mode-badge', <Component>[Component.text('TEST MODE')]);
  }
}

@css
List<StyleRule> get appTestModeBadgeStyles => <StyleRule>[
  css('.app-test-mode-badge')
      .styles(
        display: Display.inlineBlock,
        padding: const Padding.symmetric(horizontal: Unit.pixels(6), vertical: Unit.pixels(2)),
        radius: const BorderRadius.circular(Unit.pixels(4)),
        backgroundColor: AppColors.ink,
      )
      .combine(AppTextStyles.monoCaption)
      .combine(
        const Styles(
          color: AppColors.accent,
          fontSize: Unit.pixels(10),
          fontWeight: FontWeight.w700,
          letterSpacing: Unit.em(0.06),
          lineHeight: Unit.pixels(12),
        ),
      ),
];
