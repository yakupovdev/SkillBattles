import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/league/league_rank.dart';
import 'package:skill_battles/core/presentation/widgets/app_reveal.dart';
import 'package:skill_battles/core/presentation/widgets/league_emblem.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/welcome_layout.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/welcome_navigation.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/welcome_sticker.dart';

/// The full-bleed ink band: heading, the league ladder and the
/// calibration note.
final class LeaguesSection extends StatelessComponent {
  const LeaguesSection({super.key});

  @override
  Component build(BuildContext context) {
    return section(
      id: WelcomeAnchors.leagues,
      classes: 'welcome-section welcome-leagues',
      attributes: const <String, String>{'tabindex': '-1'},
      const <Component>[
        div(classes: 'welcome-container welcome-leagues__inner', <Component>[
          WelcomeSectionHeader(
            eyebrow: 'Leagues · One ladder per subject',
            isOnDark: true,
            isLarge: true,
            title: <Component>[
              WelcomeTitleLine('Climb 27 tiers.'),
              WelcomeTitleLine('Bronze to Legend.', color: AppColors.accent),
            ],
            body:
                'Eight leagues with three divisions each, then Master, Grandmaster and Legend. Win ranked '
                'battles to move up; your league shows on the leaderboard.',
          ),
          LeagueLadder(),
          CalibrationNote(),
        ]),
      ],
    );
  }
}

/// Eleven leagues, lowest first, with emblems growing left to right. The
/// emblems rise in order when the ladder enters view.
final class LeagueLadder extends StatelessComponent {
  const LeagueLadder({super.key});

  static const List<LeagueStepData> _steps = <LeagueStepData>[
    LeagueStepData(LeagueRank(League.bronze, 3), 52, 'I · II · III'),
    LeagueStepData(LeagueRank(League.iron, 3), 56, 'I · II · III'),
    LeagueStepData(LeagueRank(League.silver, 3), 60, 'I · II · III'),
    LeagueStepData(LeagueRank(League.gold, 3), 64, 'I · II · III'),
    LeagueStepData(LeagueRank(League.platinum, 3), 68, 'I · II · III'),
    LeagueStepData(LeagueRank(League.diamond, 3), 72, 'I · II · III'),
    LeagueStepData(LeagueRank(League.emerald, 3), 78, 'I · II · III'),
    LeagueStepData(LeagueRank(League.brilliant, 3), 84, 'I · II · III'),
    LeagueStepData(LeagueRank(League.master), 92, 'ONE TIER'),
    LeagueStepData(LeagueRank(League.grandmaster), 100, 'ONE TIER'),
    LeagueStepData(LeagueRank(League.legend), 108, 'THE TOP'),
  ];

  @override
  Component build(BuildContext context) {
    return AppReveal(
      tag: 'ol',
      classes: 'welcome-ladder',
      fades: false,
      child: Component.fragment(<Component>[
        for (int i = 0; i < _steps.length; i++) LeagueStep(index: i, data: _steps[i]),
      ]),
    );
  }
}

final class LeagueStepData {
  const LeagueStepData(this.rank, this.size, this.caption);

  final LeagueRank rank;
  final double size;
  final String caption;
}

/// One league: emblem, name and divisions.
final class LeagueStep extends StatelessComponent {
  const LeagueStep({required this.index, required this.data, super.key});

  final int index;
  final LeagueStepData data;

  @override
  Component build(BuildContext context) {
    final League league = data.rank.league;
    final bool isLegend = league == League.legend;
    final Component? sticker = switch (league) {
      League.bronze => const WelcomeSticker(
        stickerId: StickerId.crying,
        size: 56,
        rotation: -8,
        firstDelay: Duration(milliseconds: 700),
        // Bottom of the sticker 12 px above the emblem, centred on it.
        position: Position.absolute(
          bottom: Unit.expression('calc(100% + 12px)'),
          left: Unit.expression('calc(50% - 28px)'),
        ),
      ),
      League.legend => const WelcomeSticker(
        stickerId: StickerId.ez,
        size: 64,
        rotation: 10,
        firstDelay: Duration(milliseconds: 1100),
        position: Position.absolute(right: Unit.pixels(-8), top: Unit.pixels(-56)),
      ),
      _ => null,
    };
    return li(
      classes: isLegend ? 'welcome-league welcome-league--legend' : 'welcome-league',
      styles: Styles(raw: <String, String>{'--step': '$index'}),
      <Component>[
        span(classes: 'welcome-league__rise', <Component>[
          span(classes: 'welcome-league__lift', <Component>[
            LeagueEmblem(rank: data.rank, size: data.size),
            ?sticker,
          ]),
        ]),
        div(classes: 'welcome-league__text', <Component>[
          span(
            classes: isLegend ? 'welcome-league__name welcome-league__name--legend' : 'welcome-league__name',
            <Component>[Component.text(league.displayName)],
          ),
          span(classes: 'welcome-league__caption', <Component>[Component.text(data.caption)]),
        ]),
      ],
    );
  }
}

/// "×2 ELO" while you calibrate.
final class CalibrationNote extends StatelessComponent {
  const CalibrationNote({super.key});

  @override
  Component build(BuildContext context) {
    return const div(classes: 'welcome-calibration', <Component>[
      span(classes: 'welcome-calibration__chip', <Component>[Component.text('×2 ELO')]),
      span(classes: 'welcome-calibration__text', <Component>[
        Component.text(
          'While you calibrate — your first 5 ranked battles in each subject — rating changes are doubled.',
        ),
      ]),
    ]);
  }
}

@css
List<StyleRule> get welcomeLeaguesStyles => <StyleRule>[
  css('.welcome-leagues').styles(
    padding: const Padding.only(top: Unit.pixels(112), bottom: Unit.pixels(96)),
    backgroundColor: AppColors.ink,
  ),
  css('.welcome-leagues__inner').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(56)),
  ),
  css('.welcome-ladder').styles(
    display: Display.flex,
    border: const Border.only(
      bottom: BorderSide(color: AppColors.onDarkLine, width: Unit.pixels(1)),
    ),
    alignItems: AlignItems.end,
  ),
  css('.welcome-league').styles(
    display: Display.flex,
    padding: const Padding.only(bottom: Unit.pixels(24)),
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.center,
    gap: const Gap.row(Unit.pixels(16)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.welcome-league__rise').styles(display: Display.flex),
  css('.welcome-league__lift').styles(
    display: Display.flex,
    position: const Position.relative(),
    raw: const <String, String>{'transition': 'transform 200ms ease'},
  ),
  css.media(
    const MediaQuery.raw('(hover: hover) and (pointer: fine) and (prefers-reduced-motion: no-preference)'),
    <StyleRule>[
      css('.welcome-league__lift:hover').styles(
        transform: const Transform.combine(<Transform>[Transform.translate(y: Unit.pixels(-6)), Transform.scale(1.06)]),
      ),
    ],
  ),
  css('.welcome-league__text').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.center,
    gap: const Gap.row(Unit.pixels(4)),
  ),
  css('.welcome-league__name')
      .combine(AppTextStyles.bodyMd)
      .combine(const Styles(color: AppColors.white, fontWeight: FontWeight.w600)),
  css('.welcome-league__name--legend').styles(color: AppColors.accent),
  css('.welcome-league__caption')
      .combine(AppTextStyles.monoCaption)
      .combine(const Styles(color: AppColors.onDarkFaint, letterSpacing: Unit.em(0.06), whiteSpace: WhiteSpace.noWrap)),
  css('.welcome-ladder.app-reveal--armed:not(.app-reveal--in) .welcome-league__rise').styles(
    opacity: 0,
    transform: const Transform.translate(y: Unit.pixels(32)),
  ),
  css('.welcome-ladder.app-reveal--in .welcome-league__rise').styles(
    raw: const <String, String>{
      'transition':
          'opacity 500ms cubic-bezier(0.2, 0.7, 0.2, 1) calc(var(--step) * 60ms), '
          'transform 500ms cubic-bezier(0.2, 0.7, 0.2, 1) calc(var(--step) * 60ms)',
    },
  ),
  // The Legend emblem keeps a slow amber glow once it has risen.
  css('.welcome-league--legend .welcome-league__rise').styles(
    raw: const <String, String>{'animation': 'welcome-glow 2.4s ease-in-out 1.2s infinite alternate both'},
  ),
  css.keyframes('welcome-glow', <String, Styles>{
    'from': Styles(
      filter: Filter.dropShadow(
        offsetX: Unit.zero,
        offsetY: Unit.zero,
        spread: const Unit.pixels(16),
        color: AppColors.accent.withOpacity(0),
      ),
    ),
    'to': Styles(
      filter: Filter.dropShadow(
        offsetX: Unit.zero,
        offsetY: Unit.zero,
        spread: const Unit.pixels(16),
        color: AppColors.accent.withOpacity(0.45),
      ),
    ),
  }),
  css('.welcome-calibration').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(10)),
  ),
  css('.welcome-calibration__chip')
      .combine(AppTextStyles.monoCaption)
      .combine(
        const Styles(
          padding: Padding.symmetric(horizontal: Unit.pixels(8), vertical: Unit.pixels(3)),
          radius: BorderRadius.circular(Unit.pixels(6)),
          color: AppColors.white,
          fontWeight: FontWeight.w600,
          letterSpacing: Unit.em(0.04),
          backgroundColor: AppColors.primary,
        ),
      ),
  css('.welcome-calibration__text')
      .combine(AppTextStyles.bodyMd)
      .combine(const Styles(color: AppColors.onDarkMuted, lineHeight: Unit.pixels(20))),
  css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), <StyleRule>[
    css('.welcome-ladder.app-reveal--in .welcome-league__rise').styles(
      raw: const <String, String>{'transition': 'none'},
    ),
    css('.welcome-league--legend .welcome-league__rise').styles(raw: const <String, String>{'animation': 'none'}),
    css('.welcome-league__lift').styles(raw: const <String, String>{'transition': 'none'}),
  ]),
];
