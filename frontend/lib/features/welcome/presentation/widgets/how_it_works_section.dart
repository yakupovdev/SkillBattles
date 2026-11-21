import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_reveal.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/welcome_layout.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/welcome_navigation.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/welcome_sticker.dart';

/// "Pick. Match. Play. Review." — the four steps of a battle.
final class HowItWorksSection extends StatelessComponent {
  const HowItWorksSection({super.key});

  @override
  Component build(BuildContext context) {
    return section(
      id: WelcomeAnchors.howItWorks,
      classes: 'welcome-container welcome-section welcome-steps-section',
      attributes: const <String, String>{'tabindex': '-1'},
      const <Component>[
        WelcomeSectionHeader(
          eyebrow: 'How a battle works',
          title: <Component>[Component.text('Pick. Match. Play. Review.')],
          body:
              'Pick a subject, get an opponent near your level, and play. Every battle ends with what you got '
              'right, what you missed, and why.',
        ),
        BattleSteps(),
      ],
    );
  }
}

/// The four [BattleStep]s in a row.
final class BattleSteps extends StatelessComponent {
  const BattleSteps({super.key});

  @override
  Component build(BuildContext context) {
    return const div(classes: 'welcome-steps', <Component>[
      BattleStep(
        index: 0,
        number: '01',
        title: 'Pick a subject',
        body: 'SAT Math or SAT Reading & Writing. Each one has its own rating.',
        sticker: WelcomeSticker(
          stickerId: StickerId.hmm,
          size: 64,
          rotation: -6,
          firstDelay: Duration(milliseconds: 700),
          position: Position.absolute(right: Unit.pixels(8), top: Unit.pixels(-44)),
        ),
      ),
      BattleStep(
        index: 1,
        number: '02',
        title: 'Get matched',
        body: 'Ranked search finds an opponent near your rating. Or open a private room for a friend.',
      ),
      BattleStep(
        index: 2,
        number: '03',
        title: 'Play five rounds',
        body: 'Same questions, same clock. A correct answer scores more the faster you give it.',
      ),
      BattleStep(
        index: 3,
        number: '04',
        title: 'Review every round',
        body: 'See your rating change, then the correct answer and an explanation for each question.',
        sticker: WelcomeSticker(
          stickerId: StickerId.waitWhat,
          size: 64,
          rotation: 7,
          firstDelay: Duration(milliseconds: 1100),
          position: Position.absolute(right: Unit.pixels(8), top: Unit.pixels(-44)),
        ),
      ),
    ]);
  }
}

/// One numbered step under a 2 px ink rule that draws in from the left.
final class BattleStep extends StatelessComponent {
  const BattleStep({
    required this.index,
    required this.number,
    required this.title,
    required this.body,
    this.sticker,
    super.key,
  });

  final int index;
  final String number;
  final String title;
  final String body;
  final WelcomeSticker? sticker;

  @override
  Component build(BuildContext context) {
    final WelcomeSticker? decoration = sticker;
    return AppReveal(
      classes: 'welcome-step',
      delayMs: index * 70,
      child: Component.fragment(<Component>[
        span(classes: 'welcome-step__number', <Component>[Component.text(number)]),
        h3(classes: 'welcome-step__title', <Component>[Component.text(title)]),
        p(classes: 'welcome-step__body', <Component>[Component.text(body)]),
        ?decoration,
      ]),
    );
  }
}

@css
List<StyleRule> get howItWorksStyles => <StyleRule>[
  css('.welcome-steps-section').styles(
    display: Display.flex,
    padding: const Padding.only(top: Unit.pixels(112)),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(48)),
  ),
  css('.welcome-steps').styles(display: Display.flex, gap: const Gap.column(Unit.pixels(24))),
  css('.welcome-step').styles(
    display: Display.flex,
    position: const Position.relative(),
    padding: const Padding.only(top: Unit.pixels(20)),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(12)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.welcome-step::before').styles(
    content: '',
    position: const Position.absolute(top: Unit.zero, left: Unit.zero, right: Unit.zero),
    height: const Unit.pixels(2),
    backgroundColor: AppColors.ink,
    raw: <String, String>{
      'transform-origin': 'left',
      'transition': 'transform 500ms $welcomeEase var(--reveal-delay, 0ms)',
    },
  ),
  css('.welcome-step.app-reveal--armed:not(.app-reveal--in)::before').styles(
    raw: const <String, String>{'transform': 'scaleX(0)'},
  ),
  css('.welcome-step__number')
      .combine(AppTextStyles.monoBodySm)
      .combine(const Styles(color: AppColors.primary, fontWeight: FontWeight.w600, letterSpacing: Unit.em(0.04))),
  css('.welcome-step__title').combine(AppTextStyles.titleMd).combine(const Styles(letterSpacing: Unit.em(-0.01))),
  css('.welcome-step__body')
      .combine(AppTextStyles.bodyLg)
      .combine(const Styles(color: AppColors.muted, lineHeight: Unit.pixels(22))),
];
