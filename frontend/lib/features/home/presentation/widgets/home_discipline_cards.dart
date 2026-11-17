import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/app/theme/league_colors.dart';
import 'package:skill_battles/core/domain/entity/calibration_entity.dart';
import 'package:skill_battles/core/domain/entity/rank_progress_entity.dart';
import 'package:skill_battles/core/presentation/league/league_rank.dart';
import 'package:skill_battles/core/presentation/skeleton/skeletonizer.dart';
import 'package:skill_battles/core/presentation/widgets/app_progress_bar.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';
import 'package:skill_battles/core/presentation/widgets/division_pips.dart';
import 'package:skill_battles/core/presentation/widgets/league_emblem.dart';
import 'package:skill_battles/features/account/domain/entity/discipline_stats_entity.dart';
import 'package:skill_battles/features/account/domain/entity/statistics_entity.dart';
import 'package:skill_battles/features/catalog/domain/entity/discipline_entity.dart';
import 'package:skill_battles/features/catalog/domain/entity/rank_ladder_entity.dart';
import 'package:skill_battles/features/catalog/domain/entity/rank_tier_entity.dart';
import 'package:skill_battles/features/catalog/presentation/extensions/catalog_labels.dart';

/// Selectable discipline cards from the catalogue: rating, rank, RP
/// progress, calibration or season peak — all computed by the server.
final class HomeDisciplineCards extends StatelessComponent {
  const HomeDisciplineCards({
    required this.disciplines,
    required this.statistics,
    required this.ranks,
    required this.selectedCode,
    required this.onSelected,
    super.key,
  });

  final List<DisciplineEntity> disciplines;
  final StatisticsEntity statistics;
  final RankLadderEntity? ranks;
  final String? selectedCode;
  final ValueChanged<String> onSelected;

  @override
  Component build(BuildContext context) {
    // Two cards per row, equally tall, as on the artboard.
    return div(classes: 'home-discipline-cards', <Component>[
      for (int i = 0; i < disciplines.length; i += 2)
        div(classes: 'home-discipline-cards__row', <Component>[
          for (final DisciplineEntity discipline in disciplines.skip(i).take(2))
            _DisciplineCard(
              discipline: discipline,
              stats: statistics.forDiscipline(discipline.code),
              ranks: ranks,
              isSelected: discipline.code == selectedCode,
              onTap: () => onSelected(discipline.code),
            ),
          if (i + 1 >= disciplines.length && disciplines.length > 1)
            const div(classes: 'home-discipline-cards__spacer', <Component>[]),
        ]),
    ]);
  }
}

final class _DisciplineCard extends StatelessComponent {
  const _DisciplineCard({
    required this.discipline,
    required this.stats,
    required this.ranks,
    required this.isSelected,
    required this.onTap,
  });

  final DisciplineEntity discipline;
  final DisciplineStatsEntity? stats;
  final RankLadderEntity? ranks;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Component build(BuildContext context) {
    final DisciplineStatsEntity? stats = this.stats;
    return AppTappable(
      onTap: onTap,
      radius: 16,
      isSelected: isSelected,
      semanticLabel:
          '${discipline.displayName}, rating ${stats?.rating ?? 'unknown'}, '
          '${stats?.rank.rankName ?? ''}',
      classes: isSelected ? 'home-discipline-card home-discipline-card--selected' : 'home-discipline-card',
      child: div(classes: 'home-discipline-card__body', <Component>[
        div(classes: 'home-discipline-card__top', <Component>[
          div(classes: 'home-discipline-card__titles', <Component>[
            h2(classes: 'home-discipline-card__name', <Component>[Component.text(discipline.displayName)]),
            p(classes: 'home-discipline-card__rounds', <Component>[Component.text(discipline.roundsLabel)]),
          ]),
          Skeleton.ignore(child: _SelectionMark(isSelected: isSelected)),
        ]),
        if (stats != null) _LeagueSection(stats: stats, ranks: ranks, isSelected: isSelected),
        _Footer(discipline: discipline, stats: stats, ranks: ranks, isSelected: isSelected),
      ]),
    );
  }
}

/// The league hero and the RP progress of one discipline.
final class _LeagueSection extends StatelessComponent {
  const _LeagueSection({required this.stats, required this.ranks, required this.isSelected});

  final DisciplineStatsEntity stats;
  final RankLadderEntity? ranks;
  final bool isSelected;

  @override
  Component build(BuildContext context) {
    final LeagueRank? league = LeagueRank.tryParse(stats.rank.rankCode);
    return div(classes: 'home-league-section', <Component>[
      _LeagueHero(stats: stats, league: league, isSelected: isSelected),
      _LeagueProgress(rank: stats.rank, league: league, ranks: ranks, isSelected: isSelected),
    ]);
  }
}

final class _LeagueHero extends StatelessComponent {
  const _LeagueHero({required this.stats, required this.league, required this.isSelected});

  final DisciplineStatsEntity stats;
  final LeagueRank? league;
  final bool isSelected;

  @override
  Component build(BuildContext context) {
    final LeagueRank? league = this.league;
    final LeaguePalette? palette = league == null ? null : LeagueColors.of(league.league);
    final int? division = league?.division;
    return div(classes: 'home-league-hero', <Component>[
      if (league != null && palette != null) _EmblemCircle(league: league, palette: palette),
      div(classes: 'home-league-hero__info', <Component>[
        const p(classes: 'home-league-hero__caption', <Component>[Component.text('YOUR LEAGUE')]),
        p(
          classes: 'home-league-hero__rank',
          styles: palette == null ? null : Styles(color: palette.nameText),
          <Component>[Component.text(stats.rank.rankName)],
        ),
        if (league != null && division != null)
          Skeleton.leaf(
            child: DivisionPips(
              division: division,
              color: LeagueColors.of(league.league).deep,
              emptyColor: isSelected ? AppColors.primaryLine : AppColors.divider,
            ),
          ),
      ]),
      div(classes: 'home-league-hero__rating', <Component>[
        p(
          classes: 'home-league-hero__rating-value',
          styles: Styles(color: isSelected ? AppColors.primary : AppColors.ink),
          <Component>[Component.text('${stats.rating}')],
        ),
        const p(classes: 'home-league-hero__rating-label', <Component>[Component.text('Elo rating')]),
      ]),
    ]);
  }
}

final class _EmblemCircle extends StatelessComponent {
  const _EmblemCircle({required this.league, required this.palette});

  final LeagueRank league;
  final LeaguePalette palette;

  @override
  Component build(BuildContext context) {
    return Skeleton.leaf(
      child: div(
        classes: 'home-league-hero__emblem',
        styles: Styles(
          border: Border.all(color: palette.base, width: const Unit.pixels(1)),
          // Inline, so the bone keeps the circle while loading.
          radius: const BorderRadius.circular(Unit.percent(50)),
          backgroundColor: palette.tint,
        ),
        <Component>[LeagueEmblem(rank: league, size: 96)],
      ),
    );
  }
}

final class _LeagueProgress extends StatelessComponent {
  const _LeagueProgress({required this.rank, required this.league, required this.ranks, required this.isSelected});

  final RankProgressEntity rank;
  final LeagueRank? league;
  final RankLadderEntity? ranks;
  final bool isSelected;

  @override
  Component build(BuildContext context) {
    final int? target = rank.divisionRpTarget;
    final RankTierEntity? nextTier = ranks?.next(rank.rankCode);
    final LeagueRank? current = league;
    final Color fill = current == null
        ? (isSelected ? AppColors.primary : AppColors.ink)
        : LeagueColors.of(current.league).deep;
    return div(classes: 'home-league-progress', <Component>[
      div(classes: 'home-league-progress__row', <Component>[
        p(classes: 'home-league-progress__text', <Component>[
          span(<Component>[
            Component.text(target == null ? 'Open tier · no RP cap' : '${rank.divisionRpCurrent} / $target RP'),
          ]),
          if (target != null && nextTier != null)
            span(classes: 'home-league-progress__next-tier', <Component>[
              Component.text(' · to ${nextTier.displayName}'),
            ]),
        ]),
        if (current != null)
          Skeleton.ignore(
            child: _NextLeague(nextLeague: _nextLeague(ranks, rank.rankCode, current)),
          ),
      ]),
      if (target != null)
        Skeleton.leaf(
          child: AppProgressBar(
            fraction: rank.fraction ?? 1,
            color: fill,
            trackColor: isSelected ? AppColors.primaryLine : AppColors.divider,
            height: 8,
          ),
        ),
    ]);
  }
}

/// The first tier of the next league, from the server ladder; `null` while
/// the ladder is missing or in the top league.
RankTierEntity? _nextLeague(RankLadderEntity? ranks, String rankCode, LeagueRank current) {
  if (ranks == null) return null;
  final List<RankTierEntity> tiers = ranks.tiers;
  final int index = tiers.indexWhere((RankTierEntity t) => t.code == rankCode);
  if (index < 0) return null;
  for (int i = index + 1; i < tiers.length; i++) {
    if (LeagueRank.tryParse(tiers[i].code)?.league != current.league) {
      return tiers[i];
    }
  }
  return null;
}

final class _NextLeague extends StatelessComponent {
  const _NextLeague({required this.nextLeague});

  final RankTierEntity? nextLeague;

  @override
  Component build(BuildContext context) {
    final RankTierEntity? tier = nextLeague;
    final LeagueRank? rank = tier == null ? null : LeagueRank.tryParse(tier.code);
    if (tier == null || rank == null) return const span(<Component>[]);
    return div(classes: 'home-next-league', <Component>[
      const span(classes: 'home-next-league__label', <Component>[Component.text('Next')]),
      LeagueEmblem(rank: rank, size: 22, dimmed: true),
      span(classes: 'home-next-league__name', <Component>[Component.text(rank.league.displayName)]),
    ]);
  }
}

/// Calibration or season peak below a line, then rare notices.
final class _Footer extends StatelessComponent {
  const _Footer({required this.discipline, required this.stats, required this.ranks, required this.isSelected});

  final DisciplineEntity discipline;
  final DisciplineStatsEntity? stats;
  final RankLadderEntity? ranks;
  final bool isSelected;

  @override
  Component build(BuildContext context) {
    final DisciplineStatsEntity? stats = this.stats;
    final CalibrationEntity? calibration = stats?.calibration;
    return div(
      classes: isSelected ? 'home-card-footer home-card-footer--selected' : 'home-card-footer',
      <Component>[
        if (stats != null && calibration != null)
          if (calibration.isCalibrating)
            div(classes: 'home-card-footer__calibration', <Component>[
              const _CalibrationChip(),
              p(
                classes: 'home-card-footer__text',
                styles: isSelected ? const Styles(color: AppColors.primaryInk) : null,
                <Component>[
                  Component.text(
                    'Calibration · ${calibration.matchesRemaining} of '
                    '${calibration.completedMatches + calibration.matchesRemaining} '
                    'matches left',
                  ),
                ],
              ),
            ])
          else
            p(classes: 'home-card-footer__text', <Component>[
              Component.text(
                'Calibrated · Season peak ${stats.seasonPeakRating} '
                '${ranks.nameOf(stats.seasonPeakRankCode)}',
              ),
            ]),
        if (stats != null && stats.seasonRolloverPending)
          const p(classes: 'home-card-footer__rollover', <Component>[
            Component.text('Season reset pending — finishing your last match of the previous season.'),
          ]),
        if (!discipline.contentAvailable)
          const p(classes: 'home-card-footer__unavailable', <Component>[
            Component.text('Questions are being restocked — not available right now.'),
          ]),
      ],
    );
  }
}

/// "×2 ELO": calibration matches move the rating twice as fast (K 64
/// instead of 32).
final class _CalibrationChip extends StatelessComponent {
  const _CalibrationChip();

  @override
  Component build(BuildContext context) {
    return const span(classes: 'home-calibration-chip', <Component>[Component.text('×2 ELO')]);
  }
}

final class _SelectionMark extends StatelessComponent {
  const _SelectionMark({required this.isSelected});

  final bool isSelected;

  @override
  Component build(BuildContext context) {
    return span(
      classes: isSelected ? 'home-selection-mark home-selection-mark--selected' : 'home-selection-mark',
      attributes: const <String, String>{'aria-hidden': 'true'},
      <Component>[
        if (isSelected) const AppSvgIcon(AppIcons.check, width: 12, height: 12),
      ],
    );
  }
}

@css
List<StyleRule> get homeDisciplineCardsStyles => <StyleRule>[
  css('.home-discipline-cards').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(20)),
  ),
  css('.home-discipline-cards__row').styles(
    display: Display.flex,
    flexDirection: FlexDirection.row,
    alignItems: AlignItems.stretch,
    gap: const Gap.column(Unit.pixels(20)),
  ),
  css('.home-discipline-cards__row > *').styles(
    minWidth: Unit.zero,
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  // The border is added to the padding, so the content sits 30 px in from
  // the edge in both states, as on the artboard.
  css('.home-discipline-card').styles(
    padding: const Padding.all(Unit.pixels(29)),
    border: Border.all(color: AppColors.border, width: const Unit.pixels(1)),
    radius: const BorderRadius.circular(Unit.pixels(16)),
    transition: const Transition('all', duration: Duration(milliseconds: 150)),
  ),
  css('.home-discipline-card--selected').styles(
    padding: const Padding.all(Unit.pixels(28)),
    border: Border.all(color: AppColors.primary, width: const Unit.pixels(2)),
    backgroundColor: AppColors.primarySurface,
  ),
  css('.home-discipline-card__body').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(20)),
  ),
  css('.home-discipline-card__top').styles(
    display: Display.flex,
    alignItems: AlignItems.start,
    gap: const Gap.column(Unit.pixels(12)),
  ),
  css('.home-discipline-card__titles').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(4)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.home-discipline-card__name')
      .styles(overflow: Overflow.hidden, textOverflow: TextOverflow.ellipsis, whiteSpace: WhiteSpace.noWrap)
      .combine(AppTextStyles.titleXlCompact),
  css('.home-discipline-card__rounds').combine(AppTextStyles.bodySm).combine(const Styles(color: AppColors.muted)),
  css('.home-selection-mark').styles(
    display: Display.flex,
    width: const Unit.pixels(24),
    height: const Unit.pixels(24),
    border: Border.all(color: AppColors.borderStrong, width: const Unit.pixels(1.5)),
    radius: const BorderRadius.circular(Unit.percent(50)),
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.center,
    flex: const Flex(shrink: 0),
  ),
  css('.home-selection-mark--selected').styles(
    border: Border.none,
    backgroundColor: AppColors.primary,
  ),
  css('.home-league-section').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(20)),
  ),
  css('.home-league-hero').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(16)),
  ),
  css('.home-league-hero__emblem').styles(
    display: Display.flex,
    width: const Unit.pixels(112),
    height: const Unit.pixels(112),
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.center,
    flex: const Flex(shrink: 0),
  ),
  css('.home-league-hero__info').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(6)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.home-league-hero__caption')
      .combine(AppTextStyles.monoCaption)
      .combine(const Styles(color: AppColors.muted, letterSpacing: Unit.em(0.1))),
  css('.home-league-hero__rank')
      .styles(
        maxWidth: const Unit.percent(100),
        overflow: Overflow.hidden,
        textOverflow: TextOverflow.ellipsis,
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.titleXl)
      .combine(
        const Styles(fontSize: Unit.pixels(34), letterSpacing: Unit.em(-0.02), lineHeight: Unit.pixels(38)),
      ),
  css('.home-league-hero__rating').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.end,
    gap: const Gap.row(Unit.pixels(2)),
    flex: const Flex(shrink: 0),
  ),
  css('.home-league-hero__rating-value')
      .combine(AppTextStyles.monoXl)
      .combine(
        const Styles(fontSize: Unit.pixels(28), letterSpacing: Unit.em(-0.02), lineHeight: Unit.pixels(32)),
      ),
  css('.home-league-hero__rating-label').combine(AppTextStyles.bodyXs).combine(const Styles(color: AppColors.muted)),
  css('.home-league-progress').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(10)),
  ),
  css('.home-league-progress__row').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(12)),
  ),
  css('.home-league-progress__text')
      .styles(
        minWidth: Unit.zero,
        flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
      )
      .combine(AppTextStyles.eyebrow)
      .combine(const Styles(color: AppColors.inkSoft, letterSpacing: Unit.zero)),
  css('.home-league-progress__next-tier').styles(color: AppColors.muted),
  css('.home-next-league').styles(
    display: Display.flex,
    opacity: 0.55,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(6)),
    flex: const Flex(shrink: 0),
  ),
  css('.home-next-league__label').combine(AppTextStyles.bodyXs).combine(const Styles(color: AppColors.muted)),
  css('.home-next-league__name')
      .combine(AppTextStyles.bodyXs)
      .combine(const Styles(color: AppColors.inkSoft, fontWeight: FontWeight.w600)),
  css('.home-card-footer').styles(
    display: Display.flex,
    padding: const Padding.only(top: Unit.pixels(16)),
    border: const Border.only(
      top: BorderSide(color: AppColors.divider, width: Unit.pixels(1)),
    ),
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(8)),
  ),
  css('.home-card-footer--selected').styles(
    border: const Border.only(
      top: BorderSide(color: AppColors.primaryLine, width: Unit.pixels(1)),
    ),
  ),
  css('.home-card-footer__calibration').styles(
    display: Display.flex,
    maxWidth: const Unit.percent(100),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(8)),
  ),
  css('.home-card-footer__text')
      .styles(minWidth: Unit.zero)
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.muted)),
  css('.home-card-footer__rollover').combine(AppTextStyles.bodyXs).combine(const Styles(color: AppColors.accentText)),
  css('.home-card-footer__unavailable').combine(AppTextStyles.bodyXs).combine(const Styles(color: AppColors.danger)),
  css('.home-calibration-chip')
      .styles(
        padding: const Padding.symmetric(horizontal: Unit.pixels(8), vertical: Unit.pixels(3)),
        radius: const BorderRadius.circular(Unit.pixels(6)),
        flex: const Flex(shrink: 0),
        backgroundColor: AppColors.primary,
      )
      .combine(AppTextStyles.monoCaption)
      .combine(const Styles(color: AppColors.white, fontWeight: FontWeight.w600, letterSpacing: Unit.em(0.04))),
];
