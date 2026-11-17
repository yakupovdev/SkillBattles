import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';

/// Where the [AppLogo] is placed.
enum AppLogoVariant {
  /// Blue mark, ink wordmark — the top bar.
  onLight,

  /// Inverse mark on a white tile, white wordmark — the blue auth panel.
  onPrimary,
}

/// The SkillBattles mark (two chevrons facing each other) with the wordmark.
final class AppLogo extends StatelessComponent {
  const AppLogo({this.variant = AppLogoVariant.onLight, super.key});

  final AppLogoVariant variant;

  @override
  Component build(BuildContext context) {
    final bool onPrimary = variant == AppLogoVariant.onPrimary;
    final double markSize = onPrimary ? 32 : 28;
    return div(
      classes: 'app-logo',
      attributes: const <String, String>{'role': 'img', 'aria-label': 'SkillBattles'},
      <Component>[
        AppSvgIcon(onPrimary ? AppIcons.logoMarkInverse : AppIcons.logoMark, width: markSize, height: markSize),
        span(
          classes: onPrimary ? 'app-logo__wordmark app-logo__wordmark--on-primary' : 'app-logo__wordmark',
          attributes: const <String, String>{'aria-hidden': 'true'},
          const <Component>[Component.text('SkillBattles')],
        ),
      ],
    );
  }
}

@css
List<StyleRule> get appLogoStyles => <StyleRule>[
  css('.app-logo').styles(
    display: Display.inlineFlex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(10)),
  ),
  css('.app-logo__wordmark').combine(AppTextStyles.titleSm).styles(whiteSpace: WhiteSpace.noWrap),
  css('.app-logo__wordmark--on-primary')
      .combine(AppTextStyles.titleMd)
      .combine(const Styles(color: AppColors.white, letterSpacing: Unit.em(-0.01))),
];
