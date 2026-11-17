import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/app/theme/league_colors.dart';
import 'package:skill_battles/core/domain/entity/calibration_entity.dart';
import 'package:skill_battles/core/domain/entity/rank_progress_entity.dart';
import 'package:skill_battles/core/presentation/league/league_rank.dart';
import 'package:skill_battles/core/presentation/skeleton/skeletonizer.dart';
import 'package:skill_battles/core/presentation/widgets/app_card.dart';
import 'package:skill_battles/core/presentation/widgets/app_notice.dart';
import 'package:skill_battles/core/presentation/widgets/app_progress_bar.dart';
import 'package:skill_battles/core/presentation/widgets/league_emblem.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_discipline_stats_entity.dart';
import 'package:skill_battles/features/friends/presentation/widgets/match_counts_column.dart';

/// A friend's public stats in one discipline (Paper: "43 Friend profile —
/// loaded"): league, division progress, peaks and the ranked / private
/// counters. Not selectable.
///
/// The names come from the catalogue, resolved by the screen:
/// [disciplineName], [allTimePeakRankName], [seasonPeakRankName].
final class FriendDisciplineCard extends StatelessComponent {
  const FriendDisciplineCard({
    required this.stats,
    required this.disciplineName,
    required this.allTimePeakRankName,
    required this.seasonPeakRankName,
    super.key,
  });

  final FriendDisciplineStatsEntity stats;
  final String disciplineName;
  final String allTimePeakRankName;
  final String seasonPeakRankName;

  @override
  Component build(BuildContext context) {
    final LeagueRank? league = LeagueRank.tryParse(stats.rank.rankCode);
    return AppCard(
      color: AppColors.white,
      padding: const Padding.all(Unit.pixels(28)),
      classes: 'friend-discipline-card',
      child: Component.fragment(<Component>[
        _Head(name: disciplineName, calibration: stats.calibration),
        if (stats.seasonRolloverPending)
          Skeleton.ignore(
            child: const AppNotice(
              message:
                  'Season reset pending. These numbers update when the '
                  'new season starts.',
              tone: AppNoticeTone.warning,
            ),
          ),
        _LeagueHero(rank: stats.rank, rating: stats.rating, league: league),
        _DivisionProgress(rank: stats.rank, league: league),
        _Peaks(
          allTimeRating: stats.allTimePeakRating,
          allTimeRank: allTimePeakRankName,
          seasonRating: stats.seasonPeakRating,
          seasonRank: seasonPeakRankName,
        ),
        _Counters(stats: stats),
      ]),
    );
  }
}

final class _Head extends StatelessComponent {
  const _Head({required this.name, required this.calibration});

  final String name;
  final CalibrationEntity calibration;

  @override
  Component build(BuildContext context) {
    return div(classes: 'friend-discipline-card__head', <Component>[
      h2(classes: 'friend-discipline-card__name', <Component>[Component.text(name)]),
      if (calibration.isCalibrating)
        div(classes: 'friend-discipline-card__calibrating', <Component>[
          const _CalibrationChip(),
          span(classes: 'friend-discipline-card__status friend-discipline-card__status--calibrating', <Component>[
            Component.text(
              'Calibrating · ${calibration.matchesRemaining} of '
              '${calibration.completedMatches + calibration.matchesRemaining}'
              ' matches left',
            ),
          ]),
        ])
      else
        span(classes: 'friend-discipline-card__status', <Component>[Component.text('Calibrated')]),
    ]);
  }
}

/// "×2 ELO", the same chip as the home discipline cards.
final class _CalibrationChip extends StatelessComponent {
  const _CalibrationChip();

  @override
  Component build(BuildContext context) {
    return span(classes: 'friend-discipline-card__chip', <Component>[Component.text('×2 ELO')]);
  }
}

final class _LeagueHero extends StatelessComponent {
  const _LeagueHero({
    required this.rank,
    required this.rating,
    required this.league,
  });

  final RankProgressEntity rank;
  final int rating;
  final LeagueRank? league;

  @override
  Component build(BuildContext context) {
    final LeagueRank? current = league;
    final LeaguePalette? palette = current == null ? null : LeagueColors.of(current.league);
    return div(classes: 'friend-discipline-card__hero', <Component>[
      if (current != null && palette != null)
        Skeleton.leaf(
          child: div(
            classes: 'friend-discipline-card__emblem',
            styles: Styles(
              border: Border.all(color: palette.base, width: const Unit.pixels(1)),
              backgroundColor: palette.tint,
            ),
            <Component>[LeagueEmblem(rank: current, size: 72)],
          ),
        ),
      div(classes: 'friend-discipline-card__league', <Component>[
        Skeleton.keep(
          child: span(classes: 'friend-discipline-card__league-label', <Component>[Component.text('LEAGUE')]),
        ),
        p(
          classes: 'friend-discipline-card__rank-name',
          styles: palette == null ? null : Styles(color: palette.nameText),
          <Component>[Component.text(rank.rankName)],
        ),
      ]),
      div(classes: 'friend-discipline-card__rating', <Component>[
        span(classes: 'friend-discipline-card__rating-value', <Component>[Component.text('$rating')]),
        Skeleton.keep(
          child: span(classes: 'friend-discipline-card__small-label', <Component>[Component.text('Elo rating')]),
        ),
      ]),
    ]);
  }
}

final class _DivisionProgress extends StatelessComponent {
  const _DivisionProgress({required this.rank, required this.league});

  final RankProgressEntity rank;
  final LeagueRank? league;

  @override
  Component build(BuildContext context) {
    final int? target = rank.divisionRpTarget;
    final LeagueRank? current = league;
    final Color fill = current == null ? AppColors.ink : LeagueColors.of(current.league).deep;
    return div(classes: 'friend-discipline-card__progress', <Component>[
      p(classes: 'friend-discipline-card__progress-label', <Component>[
        Component.text(target == null ? 'Open tier · no RP cap' : '${rank.divisionRpCurrent} / $target RP'),
      ]),
      if (target != null)
        Skeleton.leaf(
          child: AppProgressBar(
            fraction: rank.fraction ?? 1,
            color: fill,
            trackColor: AppColors.divider,
            height: 8,
          ),
        ),
    ]);
  }
}

final class _Peaks extends StatelessComponent {
  const _Peaks({
    required this.allTimeRating,
    required this.allTimeRank,
    required this.seasonRating,
    required this.seasonRank,
  });

  final int allTimeRating;
  final String allTimeRank;
  final int seasonRating;
  final String seasonRank;

  @override
  Component build(BuildContext context) {
    return div(classes: 'friend-discipline-card__section friend-discipline-card__peaks', <Component>[
      _Peak(label: 'All-time peak', rating: allTimeRating, rankName: allTimeRank),
      _Peak(label: 'Season peak', rating: seasonRating, rankName: seasonRank),
    ]);
  }
}

final class _Peak extends StatelessComponent {
  const _Peak({
    required this.label,
    required this.rating,
    required this.rankName,
  });

  final String label;
  final int rating;
  final String rankName;

  @override
  Component build(BuildContext context) {
    return div(classes: 'friend-discipline-card__peak', <Component>[
      Skeleton.keep(
        child: span(classes: 'friend-discipline-card__small-label', <Component>[Component.text(label)]),
      ),
      p(classes: 'friend-discipline-card__peak-value', <Component>[
        span(classes: 'friend-discipline-card__peak-rating', <Component>[Component.text('$rating')]),
        span(<Component>[Component.text(' · $rankName')]),
      ]),
    ]);
  }
}

final class _Counters extends StatelessComponent {
  const _Counters({required this.stats});

  final FriendDisciplineStatsEntity stats;

  @override
  Component build(BuildContext context) {
    return div(classes: 'friend-discipline-card__section friend-discipline-card__counters', <Component>[
      MatchCountsColumn(title: 'RANKED', stats: stats.ranked),
      const div(classes: 'friend-discipline-card__divider', <Component>[]),
      MatchCountsColumn(title: 'PRIVATE', stats: stats.privateMatches),
    ]);
  }
}

@css
List<StyleRule> get friendDisciplineCardStyles => <StyleRule>[
  css('.friend-discipline-card').styles(gap: const Gap.row(Unit.pixels(24))),
  css('.friend-discipline-card__head').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(12)),
  ),
  css('.friend-discipline-card__name')
      .styles(
        minWidth: Unit.zero,
        overflow: Overflow.hidden,
        flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
        textOverflow: TextOverflow.ellipsis,
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.titleXlCompact),
  css('.friend-discipline-card__calibrating').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(8)),
    flex: const Flex(grow: 0, shrink: 1, basis: Unit.auto),
  ),
  css('.friend-discipline-card__status').combine(AppTextStyles.bodySm).combine(const Styles(color: AppColors.muted)),
  css('.friend-discipline-card__status--calibrating').styles(minWidth: Unit.zero, color: AppColors.primaryInk),
  css('.friend-discipline-card__chip')
      .styles(
        padding: const Padding.symmetric(horizontal: Unit.pixels(8), vertical: Unit.pixels(3)),
        radius: const BorderRadius.circular(Unit.pixels(6)),
        flex: const Flex(shrink: 0),
        whiteSpace: WhiteSpace.noWrap,
        backgroundColor: AppColors.primary,
      )
      .combine(AppTextStyles.monoCaption)
      .combine(const Styles(color: AppColors.white, fontWeight: FontWeight.w600, letterSpacing: Unit.em(0.04))),
  css('.friend-discipline-card__hero').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(16)),
  ),
  css('.friend-discipline-card__emblem').styles(
    display: Display.flex,
    width: const Unit.pixels(88),
    height: const Unit.pixels(88),
    boxSizing: BoxSizing.borderBox,
    radius: const BorderRadius.circular(Unit.percent(50)),
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.center,
    flex: const Flex(shrink: 0),
  ),
  css('.friend-discipline-card__league').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(6)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.friend-discipline-card__league-label')
      .combine(AppTextStyles.monoCaption)
      .combine(const Styles(color: AppColors.muted, letterSpacing: Unit.em(0.1))),
  css('.friend-discipline-card__rank-name')
      .styles(
        maxWidth: const Unit.percent(100),
        overflow: Overflow.hidden,
        textOverflow: TextOverflow.ellipsis,
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.titleXl)
      .combine(
        const Styles(fontSize: Unit.pixels(30), letterSpacing: Unit.em(-0.02), lineHeight: Unit.pixels(34)),
      ),
  css('.friend-discipline-card__rating').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.end,
    gap: const Gap.row(Unit.pixels(2)),
    flex: const Flex(shrink: 0),
  ),
  css('.friend-discipline-card__rating-value')
      .combine(AppTextStyles.monoXl)
      .combine(
        const Styles(fontSize: Unit.pixels(28), letterSpacing: Unit.em(-0.02), lineHeight: Unit.pixels(32)),
      ),
  css('.friend-discipline-card__small-label')
      .combine(AppTextStyles.bodyXs)
      .combine(const Styles(color: AppColors.muted)),
  css('.friend-discipline-card__progress').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(10)),
  ),
  css('.friend-discipline-card__progress-label')
      .combine(AppTextStyles.eyebrow)
      .combine(const Styles(color: AppColors.inkSoft, letterSpacing: Unit.zero)),
  // A block below a 1 px divider.
  css('.friend-discipline-card__section').styles(
    display: Display.flex,
    padding: const Padding.only(top: Unit.pixels(16)),
    border: const Border.only(
      top: BorderSide(color: AppColors.divider, width: Unit.pixels(1)),
    ),
    gap: const Gap.column(Unit.pixels(24)),
  ),
  css('.friend-discipline-card__peaks').styles(alignItems: AlignItems.start),
  css('.friend-discipline-card__peak, .friend-discipline-card__counters > .match-counts-column').styles(
    minWidth: Unit.zero,
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.friend-discipline-card__peak').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(4)),
  ),
  css('.friend-discipline-card__peak-value').combine(AppTextStyles.bodyLg),
  css('.friend-discipline-card__peak-rating')
      .combine(AppTextStyles.monoBodyMd)
      .combine(const Styles(fontSize: Unit.pixels(15), fontWeight: FontWeight.w600)),
  css('.friend-discipline-card__divider').styles(
    width: const Unit.pixels(1),
    flex: const Flex(shrink: 0),
    backgroundColor: AppColors.divider,
  ),
];
