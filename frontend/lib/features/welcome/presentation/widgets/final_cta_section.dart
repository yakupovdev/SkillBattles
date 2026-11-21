import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_reveal.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_link.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/welcome_layout.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/welcome_navigation.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/welcome_ring.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/welcome_sticker.dart';

/// The closing call to action on a blue panel.
final class FinalCtaSection extends StatelessComponent {
  const FinalCtaSection({super.key});

  @override
  Component build(BuildContext context) {
    return section(classes: 'welcome-container welcome-final', const <Component>[FinalCtaPanel()]);
  }
}

/// Headline, one paragraph, "Create account & play" and a "Log in" link.
final class FinalCtaPanel extends StatelessComponent {
  const FinalCtaPanel({super.key});

  @override
  Component build(BuildContext context) {
    return AppReveal(
      classes: 'welcome-final__panel',
      child: Component.fragment(<Component>[
        const WelcomeRing(
          size: 420,
          top: -60,
          right: -40,
          color: AppColors.onPrimaryRingOuter,
          periodSeconds: 8,
        ),
        const WelcomeRing(
          size: 260,
          top: 20,
          right: 40,
          color: AppColors.onPrimaryRingInner,
          periodSeconds: 8,
          isInner: true,
        ),
        const h2(classes: 'welcome-final__title', <Component>[
          WelcomeTitleLine('Your first battle is'),
          WelcomeTitleLine('one click away.', color: AppColors.accent),
        ]),
        const p(classes: 'welcome-final__body', <Component>[
          Component.text(
            'Create an account, pick SAT Math or Reading & Writing, and play right away. Both ratings start at 1000.',
          ),
        ]),
        div(classes: 'welcome-final__actions', <Component>[
          AppButton(
            label: 'Create account & play',
            variant: AppButtonVariant.accent,
            onPressed: context.goToSignUp,
          ),
          div(classes: 'welcome-final__login', <Component>[
            const span(<Component>[Component.text('Already have an account? ')]),
            div(classes: 'welcome-final__link', <Component>[
              AppTextLink(
                label: 'Log in',
                focusColor: AppColors.white,
                style: _linkStyle,
                onPressed: context.goToLogIn,
              ),
            ]),
          ]),
        ]),
        const WelcomeSticker(
          stickerId: StickerId.lol,
          size: 88,
          rotation: -7,
          firstDelay: Duration(milliseconds: 700),
          position: Position.absolute(right: Unit.pixels(120), top: Unit.pixels(64)),
        ),
      ]),
    );
  }

  // No color: the link takes the wrapper's (white, amber on hover).
  static const Styles _linkStyle = Styles(
    padding: Padding.symmetric(vertical: Unit.pixels(14)),
    fontFamily: AppFonts.body,
    fontSize: Unit.pixels(15),
    fontWeight: FontWeight.w600,
    textDecoration: TextDecoration(line: TextDecorationLine.underline),
    lineHeight: Unit.pixels(20),
  );
}

@css
List<StyleRule> get welcomeFinalStyles => <StyleRule>[
  css('.welcome-final').styles(padding: const Padding.symmetric(vertical: Unit.pixels(112))),
  css('.welcome-final__panel').styles(
    display: Display.flex,
    position: const Position.relative(),
    padding: const Padding.symmetric(horizontal: Unit.pixels(72), vertical: Unit.pixels(80)),
    radius: const BorderRadius.circular(Unit.pixels(24)),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(32)),
    backgroundColor: AppColors.primary,
    raw: const <String, String>{'overflow': 'clip'},
  ),
  css('.welcome-final__panel > :not(.welcome-ring):not(.welcome-sticker)').styles(
    position: const Position.relative(),
  ),
  css('.welcome-final__title').combine(AppTextStyles.displayMd).combine(const Styles(color: AppColors.white)),
  css('.welcome-final__body')
      .combine(AppTextStyles.bodyXl)
      .combine(const Styles(maxWidth: Unit.pixels(520), color: AppColors.onPrimaryBody)),
  css('.welcome-final__actions').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(24)),
  ),
  css('.welcome-final__login')
      .combine(AppTextStyles.bodyLg)
      .combine(
        const Styles(
          display: Display.flex,
          alignItems: AlignItems.center,
          color: AppColors.onPrimaryBody,
          lineHeight: Unit.pixels(20),
          whiteSpace: WhiteSpace.pre,
        ),
      ),
  css('.welcome-final__link').styles(color: AppColors.white),
  css('.welcome-final__link:hover').styles(color: AppColors.accent),
];
