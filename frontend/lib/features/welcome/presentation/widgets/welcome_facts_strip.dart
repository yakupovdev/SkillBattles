import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_count_up.dart';
import 'package:skill_battles/core/presentation/widgets/app_reveal.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/welcome_layout.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/welcome_sticker.dart';

/// Four product facts between two rules. The numbers count up once when the
/// strip comes into view.
final class WelcomeFactsStrip extends StatelessComponent {
  const WelcomeFactsStrip({super.key});

  @override
  Component build(BuildContext context) {
    return div(classes: 'welcome-container welcome-facts', const <Component>[
      ul(classes: 'welcome-facts__list', <Component>[
        _FactItem(index: 0, value: 5, durationMs: 600, caption: 'ROUNDS PER BATTLE', spoken: '5 rounds per battle'),
        _FactItem(index: 1, value: 2, durationMs: 600, caption: 'SAT DISCIPLINES', spoken: '2 SAT disciplines'),
        _FactItem(
          index: 2,
          value: 27,
          durationMs: 600,
          caption: 'LEAGUE TIERS TO CLIMB',
          spoken: '27 league tiers to climb',
        ),
        _FactItem(
          index: 3,
          value: 1000,
          durationMs: 1000,
          caption: 'STARTING RATING',
          spoken: 'Starting rating 1000',
          isAccent: true,
        ),
      ]),
      // Sits on the strip's top border, above the first fact.
      WelcomeSticker(
        stickerId: StickerId.tooSlow,
        size: 64,
        rotation: 6,
        firstDelay: Duration(milliseconds: 300),
        position: Position.absolute(left: Unit.pixels(120), top: Unit.pixels(-40)),
      ),
    ]);
  }
}

final class _FactItem extends StatelessComponent {
  const _FactItem({
    required this.index,
    required this.value,
    required this.durationMs,
    required this.caption,
    required this.spoken,
    this.isAccent = false,
  });

  final int index;
  final int value;
  final int durationMs;
  final String caption;
  final String spoken;
  final bool isAccent;

  @override
  Component build(BuildContext context) {
    return AppReveal(
      tag: 'li',
      classes: index == 0 ? 'welcome-fact' : 'welcome-fact welcome-fact--divided',
      delayMs: index * 70,
      child: Component.fragment(<Component>[
        WelcomeSrOnly(spoken),
        div(
          classes: 'welcome-fact__content',
          attributes: const <String, String>{'aria-hidden': 'true'},
          <Component>[
            span(
              classes: isAccent ? 'welcome-fact__number welcome-fact__number--accent' : 'welcome-fact__number',
              <Component>[AppCountUp(from: 0, to: value, durationMs: durationMs)],
            ),
            span(classes: 'welcome-fact__caption', <Component>[Component.text(caption)]),
          ],
        ),
      ]),
    );
  }
}

@css
List<StyleRule> get welcomeFactsStyles => <StyleRule>[
  css('.welcome-facts').styles(
    // Jaspr's `vertical` axis is the top and bottom sides.
    border: const Border.symmetric(
      vertical: BorderSide(color: AppColors.border, width: Unit.pixels(1)),
    ),
  ),
  css('.welcome-facts__list').styles(display: Display.flex),
  css('.welcome-fact').styles(
    padding: const Padding.symmetric(vertical: Unit.pixels(28)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
    raw: const <String, String>{'position': 'relative'},
  ),
  css('.welcome-fact--divided').styles(
    padding: const Padding.only(top: Unit.pixels(28), bottom: Unit.pixels(28), left: Unit.pixels(32)),
    border: const Border.only(
      left: BorderSide(color: AppColors.border, width: Unit.pixels(1)),
    ),
  ),
  css('.welcome-fact__content').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(6)),
  ),
  css('.welcome-fact__number').combine(AppTextStyles.monoXl),
  css('.welcome-fact__number--accent').styles(color: AppColors.primary),
  css('.welcome-fact__caption').combine(AppTextStyles.eyebrow),
];
