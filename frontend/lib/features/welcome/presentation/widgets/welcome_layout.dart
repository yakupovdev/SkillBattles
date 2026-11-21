import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_reveal.dart';

/// Easing of every motion on the landing page.
const String welcomeEase = 'cubic-bezier(0.2, 0.7, 0.2, 1)';

/// Text for assistive technology only.
final class WelcomeSrOnly extends StatelessComponent {
  const WelcomeSrOnly(this.text, {super.key});

  final String text;

  @override
  Component build(BuildContext context) => span(classes: 'welcome-sr-only', <Component>[Component.text(text)]);
}

/// Eyebrow and h2 on the left, a paragraph on the right; shared by the
/// three sections. [title] holds the heading's lines.
final class WelcomeSectionHeader extends StatelessComponent {
  const WelcomeSectionHeader({
    required this.eyebrow,
    required this.title,
    required this.body,
    this.isOnDark = false,
    this.isLarge = false,
    super.key,
  });

  final String eyebrow;
  final List<Component> title;
  final String body;
  final bool isOnDark;

  /// 56/60 heading (Leagues) instead of 40/44.
  final bool isLarge;

  @override
  Component build(BuildContext context) {
    return AppReveal(
      classes: 'welcome-section-header',
      child: Component.fragment(<Component>[
        div(classes: 'welcome-section-header__text', <Component>[
          AppEyebrow(eyebrow, color: isOnDark ? AppColors.onDarkSubtle : AppColors.muted),
          h2(
            classes: <String>[
              'welcome-section-header__title',
              if (isLarge) 'welcome-section-header__title--large',
              if (isOnDark) 'welcome-section-header__title--on-dark',
            ].join(' '),
            title,
          ),
        ]),
        p(
          classes: isOnDark
              ? 'welcome-section-header__body welcome-section-header__body--on-dark'
              : 'welcome-section-header__body',
          <Component>[Component.text(body)],
        ),
      ]),
    );
  }
}

/// A line of a heading, kept on its own line.
final class WelcomeTitleLine extends StatelessComponent {
  const WelcomeTitleLine(this.text, {this.color, super.key});

  final String text;
  final Color? color;

  @override
  Component build(BuildContext context) {
    final Color? tint = color;
    return span(
      classes: 'welcome-title-line',
      styles: tint == null ? null : Styles(color: tint),
      <Component>[Component.text(text)],
    );
  }
}

@css
List<StyleRule> get welcomeLayoutStyles => <StyleRule>[
  css('.welcome').styles(
    position: const Position.relative(),
    backgroundColor: AppColors.white,
    raw: const <String, String>{'overflow-x': 'clip'},
  ),
  css('.welcome-container').styles(
    position: const Position.relative(),
    width: const Unit.percent(100),
    maxWidth: const Unit.pixels(1200),
    margin: const Margin.symmetric(horizontal: Unit.auto),
  ),
  css('.welcome-section').styles(
    raw: const <String, String>{'scroll-margin-top': '96px'},
  ),
  css('.welcome-section:focus').styles(raw: const <String, String>{'outline': 'none'}),
  css('.welcome-sr-only').styles(
    position: const Position.absolute(),
    width: const Unit.pixels(1),
    height: const Unit.pixels(1),
    overflow: Overflow.hidden,
    raw: const <String, String>{'clip': 'rect(0 0 0 0)', 'white-space': 'nowrap'},
  ),
  css('.welcome-section-header').styles(
    display: Display.flex,
    justifyContent: JustifyContent.spaceBetween,
    alignItems: AlignItems.end,
    gap: const Gap.column(Unit.pixels(48)),
  ),
  css('.welcome-section-header__text').styles(
    display: Display.flex,
    width: const Unit.pixels(640),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(12)),
    flex: const Flex(shrink: 0),
  ),
  css('.welcome-section-header__title').combine(AppTextStyles.headlineLg),
  css('.welcome-section-header__title--large').combine(AppTextStyles.displayMd),
  css('.welcome-section-header__title--on-dark').styles(color: AppColors.white),
  css('.welcome-section-header__body')
      .combine(AppTextStyles.bodyLg)
      .combine(const Styles(width: Unit.pixels(380), color: AppColors.muted, lineHeight: Unit.pixels(22))),
  css('.welcome-section-header__body--on-dark').styles(color: AppColors.onDarkMuted),
  css('.welcome-title-line').styles(display: Display.block),
];
