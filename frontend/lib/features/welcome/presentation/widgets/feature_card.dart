import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_card.dart';
import 'package:skill_battles/core/presentation/widgets/app_reveal.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/welcome_sticker.dart';

/// A bordered feature card: title and text on top, a decorative
/// [fragment] (a picture of the product, not interactive) below. Cards of
/// a row share the tallest height. It reveals on scroll; its fragment can
/// animate from the `.app-reveal--in` class.
final class FeatureCard extends StatelessComponent {
  const FeatureCard({
    required this.title,
    required this.body,
    required this.fragment,
    required this.index,
    this.flex = 1,
    this.bodyMaxWidth,
    this.sticker,
    super.key,
  });

  final String title;
  final String body;
  final Component fragment;

  /// Position in its row, for the stagger.
  final int index;

  /// Share of the row's width.
  final double flex;
  final double? bodyMaxWidth;

  /// A sticker overhanging the card's corner (outside its box).
  final WelcomeSticker? sticker;

  @override
  Component build(BuildContext context) {
    final WelcomeSticker? decoration = sticker;
    final double? maxWidth = bodyMaxWidth;
    return AppReveal(
      classes: 'welcome-feature',
      styles: Styles(
        flex: Flex(grow: flex, shrink: 1, basis: Unit.zero),
      ),
      delayMs: index * 70,
      child: Component.fragment(<Component>[
        AppCard(
          color: AppColors.white,
          padding: const Padding.all(Unit.pixels(28)),
          classes: 'welcome-feature__card',
          child: Component.fragment(<Component>[
            div(classes: 'welcome-feature__text', <Component>[
              h3(classes: 'welcome-feature__title', <Component>[Component.text(title)]),
              p(
                classes: 'welcome-feature__body',
                styles: maxWidth == null ? null : Styles(maxWidth: Unit.pixels(maxWidth)),
                <Component>[Component.text(body)],
              ),
            ]),
            // A picture of the product: not read, not focusable.
            div(
              classes: 'welcome-feature__fragment',
              attributes: const <String, String>{'aria-hidden': 'true'},
              <Component>[fragment],
            ),
          ]),
        ),
        ?decoration,
      ]),
    );
  }
}

@css
List<StyleRule> get featureCardStyles => <StyleRule>[
  css('.welcome-feature').styles(
    display: Display.flex,
    position: const Position.relative(),
    minWidth: Unit.zero,
  ),
  css('.welcome-feature__card').styles(
    width: const Unit.percent(100),
    justifyContent: JustifyContent.spaceBetween,
    gap: const Gap.row(Unit.pixels(28)),
  ),
  css('.welcome-feature__text').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(8)),
  ),
  css('.welcome-feature__title').combine(AppTextStyles.titleLg).combine(const Styles(letterSpacing: Unit.em(-0.01))),
  css('.welcome-feature__body')
      .combine(AppTextStyles.bodyLg)
      .combine(const Styles(color: AppColors.muted, lineHeight: Unit.pixels(22))),
];
