import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/hero_battle_preview.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/welcome_layout.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/welcome_navigation.dart';

/// Headline, copy and calls to action on the left, the live battle preview
/// on the right. The copy rises in on first paint, one line after another.
final class WelcomeHero extends StatelessComponent {
  const WelcomeHero({super.key});

  @override
  Component build(BuildContext context) {
    return section(classes: 'welcome-container welcome-hero', const <Component>[
      _HeroCopy(),
      HeroBattlePreview(),
    ]);
  }
}

final class _HeroCopy extends StatelessComponent {
  const _HeroCopy();

  @override
  Component build(BuildContext context) {
    return div(classes: 'welcome-hero__copy', <Component>[
      const _Rise(
        index: 0,
        child: AppEyebrow('SAT Math · SAT Reading & Writing · Live 1v1'),
      ),
      const h1(classes: 'welcome-hero__title', <Component>[
        _Rise(index: 1, isBlock: true, child: Component.text('Five minutes.')),
        _Rise(index: 2, isBlock: true, child: Component.text('One opponent.')),
        _Rise(
          index: 3,
          isBlock: true,
          classes: 'welcome-hero__title-accent',
          child: Component.text('Sharper mind.'),
        ),
      ]),
      const _Rise(
        index: 4,
        child: p(classes: 'welcome-hero__subline', <Component>[
          Component.text(
            'Live one-on-one battles on SAT questions. You and your opponent get the same five '
            'questions on the same clock — then a full review of every round.',
          ),
        ]),
      ),
      // Paper "HeroActions": the buttons and the footnote, 16 apart.
      div(classes: 'welcome-hero__cta-group', <Component>[
        _Rise(
          index: 5,
          child: div(classes: 'welcome-hero__actions', <Component>[
            AppButton(
              label: 'Create account & play',
              trailingIcon: const AppSvgIcon(AppIcons.arrowRight, width: 18, height: 18, color: AppColors.white),
              onPressed: context.goToSignUp,
            ),
            AppButton(label: 'Log in', variant: AppButtonVariant.outline, onPressed: context.goToLogIn),
          ]),
        ),
        const _Rise(
          index: 6,
          child: p(classes: 'welcome-hero__footnote', <Component>[
            Component.text('Free to play · Ages 13+ · Both ratings start at 1000'),
          ]),
        ),
      ]),
    ]);
  }
}

/// Fades and lifts its child on first paint, [index] x 80 ms after the
/// previous piece (CSS animation, so it also plays without JS).
final class _Rise extends StatelessComponent {
  const _Rise({required this.index, required this.child, this.isBlock = false, this.classes});

  final int index;
  final Component child;
  final bool isBlock;
  final String? classes;

  @override
  Component build(BuildContext context) {
    final String className = <String>['welcome-rise', if (isBlock) 'welcome-rise--block', ?classes].join(' ');
    final Styles style = Styles(raw: <String, String>{'--rise-index': '$index'});
    // A heading line is a span: a div is not allowed inside an h1.
    return isBlock
        ? span(classes: className, styles: style, <Component>[child])
        : div(classes: className, styles: style, <Component>[child]);
  }
}

@css
List<StyleRule> get welcomeHeroStyles => <StyleRule>[
  css('.welcome-hero').styles(
    display: Display.flex,
    padding: const Padding.only(top: Unit.pixels(80), bottom: Unit.pixels(96)),
    justifyContent: JustifyContent.spaceBetween,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(48)),
  ),
  css('.welcome-hero__copy').styles(
    display: Display.flex,
    width: const Unit.pixels(600),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(32)),
    flex: const Flex(shrink: 0),
  ),
  css('.welcome-hero__title').combine(AppTextStyles.displayLg),
  css('.welcome-hero__title-accent').styles(color: AppColors.primary),
  css('.welcome-hero__subline')
      .combine(AppTextStyles.bodyXl)
      .combine(const Styles(maxWidth: Unit.pixels(520), color: AppColors.inkSoft)),
  css('.welcome-hero__cta-group').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(16)),
  ),
  css('.welcome-hero__actions').styles(
    display: Display.flex,
    gap: const Gap.column(Unit.pixels(12)),
  ),
  css('.welcome-hero__footnote').combine(AppTextStyles.bodySm).combine(const Styles(color: AppColors.muted)),
  css('.welcome-rise--block').styles(display: Display.block),
  css('.welcome-rise').styles(
    raw: const <String, String>{
      'animation': 'welcome-rise 600ms $welcomeEase calc(var(--rise-index) * 80ms) both',
    },
  ),
  css.keyframes('welcome-rise', <String, Styles>{
    'from': const Styles(opacity: 0, transform: Transform.translate(y: Unit.pixels(16))),
    'to': const Styles(opacity: 1, transform: Transform.none),
  }),
  css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), <StyleRule>[
    css('.welcome-rise').styles(raw: const <String, String>{'animation': 'none'}),
  ]),
];
