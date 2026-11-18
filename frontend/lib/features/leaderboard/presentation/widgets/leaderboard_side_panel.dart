import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/app/theme/league_colors.dart';
import 'package:skill_battles/core/domain/entity/rank_progress_entity.dart';
import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/league/league_rank.dart';
import 'package:skill_battles/core/presentation/skeleton/skeletonizer.dart';
import 'package:skill_battles/core/presentation/widgets/app_progress_bar.dart';
import 'package:skill_battles/core/presentation/widgets/league_emblem.dart';
import 'package:skill_battles/features/account/domain/entity/discipline_stats_entity.dart';
import 'package:skill_battles/features/account/domain/entity/season_peak_entity.dart';
import 'package:skill_battles/features/catalog/domain/entity/discipline_entity.dart';
import 'package:skill_battles/features/catalog/presentation/extensions/catalog_labels.dart';
import 'package:skill_battles/features/catalog/presentation/extensions/discipline_short_name.dart';
import 'package:skill_battles/features/leaderboard/domain/entity/leaderboard_entity.dart';

/// The right column: the own position and peaks, past seasons and how the
/// ranking works.
final class LeaderboardSidePanel extends StatelessComponent {
  const LeaderboardSidePanel({
    required this.board,
    required this.disciplines,
    required this.stats,
    required this.seasons,
    super.key,
  });

  final LeaderboardEntity board;
  final List<DisciplineEntity> disciplines;

  /// Own statistics of the board's discipline; `null` when unavailable.
  final DisciplineStatsEntity? stats;
  final List<SeasonPeakEntity> seasons;

  static const double width = 340;

  @override
  Component build(BuildContext context) {
    final int? position = board.me?.position;
    final DisciplineStatsEntity? stats = this.stats;
    return div(classes: 'leaderboard-panel', <Component>[
      div(classes: 'leaderboard-panel__position', <Component>[
        p(classes: 'leaderboard-panel__muted', <Component>[
          Component.text('Your position · ${disciplines.nameOf(board.disciplineCode)}'),
        ]),
        p(classes: 'leaderboard-panel__place', <Component>[Component.text(position == null ? '—' : '#$position')]),
        p(classes: 'leaderboard-panel__muted leaderboard-panel__peaks', <Component>[
          Component.text(
            position == null
                ? 'You appear here once your season rating is ready.'
                : stats == null
                ? 'Season ${board.season.name}'
                : 'Season peak '
                      '${DisplayFormatters.grouped(stats.seasonPeakRating)} · '
                      'All-time peak '
                      '${DisplayFormatters.grouped(stats.allTimePeakRating)}',
          ),
        ]),
        if (stats != null) _SidebarLeague(rank: stats.rank),
      ]),
      div(classes: 'leaderboard-panel__seasons', <Component>[
        const h3(classes: 'leaderboard-panel__seasons-title', <Component>[Component.text('Past seasons')]),
        if (seasons.isEmpty)
          const p(classes: 'leaderboard-panel__muted', <Component>[Component.text('No finished seasons yet.')])
        else
          for (final SeasonPeakEntity season in seasons)
            _SeasonRow(season: season, disciplineName: disciplines.shortNameOf(season.disciplineCode)),
      ]),
      p(classes: 'leaderboard-panel__muted leaderboard-panel__rules', <Component>[
        Component.text(
          'Ranked by Elo, then by who reached it first. Ratings get a soft '
          'reset toward 1000 when a new season starts on '
          '${DisplayFormatters.etBoundaryDay(board.season.endsAt)}.',
        ),
      ]),
    ]);
  }
}

/// The own league: emblem, rank name and RP progress inside the tier.
final class _SidebarLeague extends StatelessComponent {
  const _SidebarLeague({required this.rank});

  final RankProgressEntity rank;

  @override
  Component build(BuildContext context) {
    final LeagueRank? league = LeagueRank.tryParse(rank.rankCode);
    final LeaguePalette? palette = league == null ? null : LeagueColors.of(league.league);
    final int? target = rank.divisionRpTarget;
    return div(
      classes: 'leaderboard-league',
      styles: Styles(backgroundColor: palette?.tint ?? AppColors.surface),
      <Component>[
        if (league != null) LeagueEmblem(rank: league, size: 52),
        div(classes: 'leaderboard-league__info', <Component>[
          div(classes: 'leaderboard-league__head', <Component>[
            p(
              classes: 'leaderboard-league__name',
              styles: palette == null ? null : Styles(color: palette.nameText),
              <Component>[Component.text(rank.rankName)],
            ),
            p(classes: 'leaderboard-league__rp', <Component>[
              Component.text(target == null ? 'Open tier' : '${rank.divisionRpCurrent} / $target RP'),
            ]),
          ]),
          if (target != null)
            Skeleton.leaf(
              child: AppProgressBar(
                fraction: rank.fraction ?? 1,
                color: palette?.deep ?? AppColors.ink,
                trackColor: AppColors.border,
              ),
            ),
        ]),
      ],
    );
  }
}

final class _SeasonRow extends StatelessComponent {
  const _SeasonRow({required this.season, required this.disciplineName});

  final SeasonPeakEntity season;
  final String disciplineName;

  @override
  Component build(BuildContext context) {
    return div(classes: 'leaderboard-season', <Component>[
      div(classes: 'leaderboard-season__main', <Component>[
        p(classes: 'leaderboard-season__name', <Component>[Component.text(season.season.name)]),
        p(classes: 'leaderboard-season__meta', <Component>[
          Component.text('$disciplineName · finished at ${DisplayFormatters.grouped(season.finalRating)}'),
        ]),
      ]),
      div(classes: 'leaderboard-season__peak', <Component>[
        p(classes: 'leaderboard-season__peak-value', <Component>[
          Component.text(DisplayFormatters.grouped(season.peakRating)),
        ]),
        p(classes: 'leaderboard-season__meta', <Component>[
          Component.text('Peak · ${formatRankCode(season.peakRankCode)}'),
        ]),
      ]),
    ]);
  }
}

@css
List<StyleRule> get leaderboardSidePanelStyles => <StyleRule>[
  css('.leaderboard-panel').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(28)),
  ),
  css('.leaderboard-panel__position').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(6)),
  ),
  css('.leaderboard-panel__muted').combine(AppTextStyles.bodySm).combine(const Styles(color: AppColors.muted)),
  css('.leaderboard-panel__peaks').styles(lineHeight: const Unit.pixels(19)),
  css('.leaderboard-panel__rules').styles(lineHeight: const Unit.pixels(20)),
  css('.leaderboard-panel__place')
      .combine(AppTextStyles.monoXl)
      .combine(
        const Styles(
          color: AppColors.primary,
          fontSize: Unit.pixels(48),
          letterSpacing: Unit.em(-0.02),
          lineHeight: Unit.pixels(52),
        ),
      ),
  css('.leaderboard-panel__seasons').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(4)),
  ),
  css('.leaderboard-panel__seasons-title')
      .styles(padding: const Padding.only(bottom: Unit.pixels(8)))
      .combine(AppTextStyles.titleMd),
  css('.leaderboard-league').styles(
    display: Display.flex,
    padding: const Padding.symmetric(horizontal: Unit.pixels(16), vertical: Unit.pixels(14)),
    border: Border.all(color: AppColors.border, width: const Unit.pixels(1)),
    radius: const BorderRadius.circular(Unit.pixels(12)),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(14)),
  ),
  css('.leaderboard-league__info').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(6)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.leaderboard-league__head').styles(
    display: Display.flex,
    alignItems: AlignItems.baseline,
    gap: const Gap.column(Unit.pixels(8)),
  ),
  css('.leaderboard-league__name')
      .styles(
        minWidth: Unit.zero,
        overflow: Overflow.hidden,
        flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
        textOverflow: TextOverflow.ellipsis,
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.titleSm),
  css('.leaderboard-league__rp')
      .styles(flex: const Flex(shrink: 0))
      .combine(AppTextStyles.eyebrow)
      .combine(const Styles(color: AppColors.muted, letterSpacing: Unit.zero)),
  css('.leaderboard-season').styles(
    display: Display.flex,
    padding: const Padding.symmetric(vertical: Unit.pixels(12)),
    border: const Border.only(
      bottom: BorderSide(color: AppColors.divider, width: Unit.pixels(1)),
    ),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(12)),
  ),
  css('.leaderboard-season__main').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(2)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.leaderboard-season__name').combine(AppTextStyles.buttonMd),
  css('.leaderboard-season__meta').combine(AppTextStyles.bodyXs).combine(const Styles(color: AppColors.muted)),
  css('.leaderboard-season__peak').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.end,
    gap: const Gap.row(Unit.pixels(2)),
  ),
  css('.leaderboard-season__peak-value')
      .combine(AppTextStyles.monoBodyMd)
      .combine(const Styles(fontWeight: FontWeight.w600)),
];
