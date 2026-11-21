import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';

/// The 88 px footer: brand and copyright on the left, "Free to play" and
/// the age badge on the right. No legal links exist in the app yet.
final class WelcomeFooter extends StatelessComponent {
  const WelcomeFooter({super.key});

  @override
  Component build(BuildContext context) {
    return footer(classes: 'welcome-footer', const <Component>[
      div(classes: 'welcome-container welcome-footer__inner', <Component>[
        div(classes: 'welcome-footer__start', <Component>[
          div(classes: 'welcome-footer__brand', <Component>[
            AppSvgIcon(AppIcons.logoMark, width: 22, height: 22),
            span(classes: 'welcome-footer__wordmark', <Component>[Component.text('SkillBattles')]),
          ]),
          span(classes: 'welcome-footer__copy', <Component>[Component.text('© 2026 SkillBattles')]),
        ]),
        div(classes: 'welcome-footer__end', <Component>[
          span(classes: 'welcome-footer__copy', <Component>[Component.text('Free to play')]),
          span(
            classes: 'welcome-footer__age',
            attributes: <String, String>{'role': 'img', 'aria-label': 'Ages 13 and up'},
            <Component>[Component.text('13+')],
          ),
        ]),
      ]),
    ]);
  }
}

@css
List<StyleRule> get welcomeFooterStyles => <StyleRule>[
  css('.welcome-footer').styles(
    border: const Border.only(
      top: BorderSide(color: AppColors.border, width: Unit.pixels(1)),
    ),
  ),
  css('.welcome-footer__inner').styles(
    display: Display.flex,
    height: const Unit.pixels(88),
    justifyContent: JustifyContent.spaceBetween,
    alignItems: AlignItems.center,
  ),
  css('.welcome-footer__start').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(20)),
  ),
  css('.welcome-footer__brand').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(8)),
  ),
  css('.welcome-footer__wordmark')
      .combine(AppTextStyles.titleSm)
      .combine(
        const Styles(fontSize: Unit.pixels(15), lineHeight: Unit.pixels(20)),
      ),
  css('.welcome-footer__copy').combine(AppTextStyles.bodySm).combine(const Styles(color: AppColors.muted)),
  css('.welcome-footer__end').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(16)),
  ),
  css('.welcome-footer__age')
      .combine(AppTextStyles.monoCaption)
      .combine(
        const Styles(
          padding: Padding.symmetric(horizontal: Unit.pixels(8), vertical: Unit.pixels(3)),
          border: Border.all(color: AppColors.borderStrong, width: Unit.pixels(1)),
          radius: BorderRadius.circular(Unit.pixels(6)),
          color: AppColors.inkSoft,
          fontWeight: FontWeight.w600,
          letterSpacing: Unit.em(0.04),
        ),
      ),
];
