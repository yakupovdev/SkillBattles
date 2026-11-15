import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/app/theme/league_colors.dart';
import 'package:skill_battles/core/domain/entity/calibration_entity.dart';
import 'package:skill_battles/core/domain/entity/rank_progress_entity.dart';
import 'package:skill_battles/core/presentation/league/league_rank.dart';
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
final class HomeDisciplineCards extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Two cards per row, equally tall, as on the artboard.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 20,
      children: <Widget>[
        for (int i = 0; i < disciplines.length; i += 2)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 20,
              children: <Widget>[
                for (final DisciplineEntity discipline
                    in disciplines.skip(i).take(2))
                  Expanded(
                    child: _DisciplineCard(
                      discipline: discipline,
                      stats: statistics.forDiscipline(discipline.code),
                      ranks: ranks,
                      isSelected: discipline.code == selectedCode,
                      onTap: () => onSelected(discipline.code),
                    ),
                  ),
                if (i + 1 >= disciplines.length && disciplines.length > 1)
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
      ],
    );
  }
}

final class _DisciplineCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final DisciplineStatsEntity? stats = this.stats;
    return AppTappable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      isSelected: isSelected,
      semanticLabel:
          '${discipline.displayName}, rating ${stats?.rating ?? 'unknown'}, '
          '${stats?.rank.rankName ?? ''}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        // The border is added to the padding, so the content sits 30 px in
        // from the edge in both states, as on the artboard.
        padding: EdgeInsets.all(isSelected ? 28 : 29),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 20,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: <Widget>[
                      Text(
                        discipline.displayName,
                        style: AppTextStyles.titleXlCompact,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        discipline.roundsLabel,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Skeleton.ignore(child: _SelectionMark(isSelected: isSelected)),
              ],
            ),
            if (stats != null)
              _LeagueSection(
                stats: stats,
                ranks: ranks,
                isSelected: isSelected,
              ),
            _Footer(
              discipline: discipline,
              stats: stats,
              ranks: ranks,
              isSelected: isSelected,
            ),
          ],
        ),
      ),
    );
  }
}

/// The league hero and the RP progress of one discipline.
final class _LeagueSection extends StatelessWidget {
  const _LeagueSection({
    required this.stats,
    required this.ranks,
    required this.isSelected,
  });

  final DisciplineStatsEntity stats;
  final RankLadderEntity? ranks;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final LeagueRank? league = LeagueRank.tryParse(stats.rank.rankCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 20,
      children: <Widget>[
        _LeagueHero(stats: stats, league: league, isSelected: isSelected),
        _LeagueProgress(
          rank: stats.rank,
          league: league,
          ranks: ranks,
          isSelected: isSelected,
        ),
      ],
    );
  }
}

final class _LeagueHero extends StatelessWidget {
  const _LeagueHero({
    required this.stats,
    required this.league,
    required this.isSelected,
  });

  final DisciplineStatsEntity stats;
  final LeagueRank? league;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final LeagueRank? league = this.league;
    final LeaguePalette? palette = league == null
        ? null
        : LeagueColors.of(league.league);
    return Row(
      spacing: 16,
      children: <Widget>[
        if (league != null && palette != null)
          _EmblemCircle(league: league, palette: palette),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: <Widget>[
              Text(
                'YOUR LEAGUE',
                style: AppTextStyles.monoCaption.copyWith(
                  letterSpacing: 0.1 * 11,
                  color: AppColors.muted,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  stats.rank.rankName,
                  style: AppTextStyles.titleXl.copyWith(
                    fontSize: 34,
                    height: 38 / 34,
                    letterSpacing: -0.02 * 34,
                    color: palette?.nameText,
                  ),
                  maxLines: 1,
                ),
              ),
              if (league != null && league.division != null)
                Skeleton.leaf(
                  child: DivisionPips(
                    division: league.division,
                    color: LeagueColors.of(league.league).deep,
                    emptyColor: isSelected
                        ? AppColors.primaryLine
                        : AppColors.divider,
                  ),
                ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 2,
          children: <Widget>[
            Text(
              '${stats.rating}',
              style: AppTextStyles.monoXl.copyWith(
                fontSize: 28,
                height: 32 / 28,
                letterSpacing: -0.02 * 28,
                color: isSelected ? AppColors.primary : AppColors.ink,
              ),
            ),
            Text(
              'Elo rating',
              style: AppTextStyles.bodyXs.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ],
    );
  }
}

final class _EmblemCircle extends StatelessWidget {
  const _EmblemCircle({required this.league, required this.palette});

  final LeagueRank league;
  final LeaguePalette palette;

  @override
  Widget build(BuildContext context) {
    return Skeleton.leaf(
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.tint,
          border: Border.all(color: palette.base),
        ),
        child: SizedBox.square(
          dimension: 112,
          child: Center(child: LeagueEmblem(rank: league, size: 96)),
        ),
      ),
    );
  }
}

final class _LeagueProgress extends StatelessWidget {
  const _LeagueProgress({
    required this.rank,
    required this.league,
    required this.ranks,
    required this.isSelected,
  });

  final RankProgressEntity rank;
  final LeagueRank? league;
  final RankLadderEntity? ranks;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final int? target = rank.divisionRpTarget;
    final RankTierEntity? nextTier = ranks?.next(rank.rankCode);
    final TextStyle mono = AppTextStyles.eyebrow.copyWith(
      letterSpacing: 0,
      color: AppColors.inkSoft,
    );
    final LeagueRank? current = league;
    final Color fill = current == null
        ? (isSelected ? AppColors.primary : AppColors.ink)
        : LeagueColors.of(current.league).deep;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: <Widget>[
        Row(
          spacing: 12,
          children: <Widget>[
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: target == null
                      ? 'Open tier · no RP cap'
                      : '${rank.divisionRpCurrent} / $target RP',
                  children: <InlineSpan>[
                    if (target != null && nextTier != null)
                      TextSpan(
                        text: ' · to ${nextTier.displayName}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                  ],
                ),
                style: mono,
              ),
            ),
            if (current != null)
              Skeleton.ignore(
                child: _NextLeague(
                  nextLeague: _nextLeague(ranks, rank.rankCode, current),
                ),
              ),
          ],
        ),
        if (target != null)
          Skeleton.leaf(
            child: AppProgressBar(
              fraction: rank.fraction ?? 1,
              color: fill,
              trackColor: isSelected
                  ? AppColors.primaryLine
                  : AppColors.divider,
              height: 8,
            ),
          ),
      ],
    );
  }
}

/// The first tier of the next league, from the server ladder; `null` while
/// the ladder is missing or in the top league.
RankTierEntity? _nextLeague(
  RankLadderEntity? ranks,
  String rankCode,
  LeagueRank current,
) {
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

final class _NextLeague extends StatelessWidget {
  const _NextLeague({required this.nextLeague});

  final RankTierEntity? nextLeague;

  @override
  Widget build(BuildContext context) {
    final RankTierEntity? tier = nextLeague;
    final LeagueRank? rank = tier == null
        ? null
        : LeagueRank.tryParse(tier.code);
    if (tier == null || rank == null) return const SizedBox.shrink();
    return Opacity(
      opacity: 0.55,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: <Widget>[
          Text(
            'Next',
            style: AppTextStyles.bodyXs.copyWith(color: AppColors.muted),
          ),
          LeagueEmblem(rank: rank, size: 22, dimmed: true),
          Text(
            rank.league.displayName,
            style: AppTextStyles.bodyXs.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

/// Calibration or season peak below a line, then rare notices.
final class _Footer extends StatelessWidget {
  const _Footer({
    required this.discipline,
    required this.stats,
    required this.ranks,
    required this.isSelected,
  });

  final DisciplineEntity discipline;
  final DisciplineStatsEntity? stats;
  final RankLadderEntity? ranks;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final DisciplineStatsEntity? stats = this.stats;
    final CalibrationEntity? calibration = stats?.calibration;
    final TextStyle textStyle = AppTextStyles.bodySm.copyWith(
      color: AppColors.muted,
    );
    final List<Widget> children = <Widget>[
      if (stats != null && calibration != null)
        if (calibration.isCalibrating)
          Row(
            spacing: 8,
            children: <Widget>[
              const _CalibrationChip(),
              Flexible(
                child: Text(
                  'Calibration · ${calibration.matchesRemaining} of '
                  '${calibration.completedMatches + calibration.matchesRemaining} '
                  'matches left',
                  style: textStyle.copyWith(
                    color: isSelected ? AppColors.primaryInk : null,
                  ),
                ),
              ),
            ],
          )
        else
          Text(
            'Calibrated · Season peak ${stats.seasonPeakRating} '
            '${ranks.nameOf(stats.seasonPeakRankCode)}',
            style: textStyle,
          ),
      if (stats != null && stats.seasonRolloverPending)
        Text(
          'Season reset pending — finishing your last match of the '
          'previous season.',
          style: AppTextStyles.bodyXs.copyWith(color: AppColors.accentText),
        ),
      if (!discipline.contentAvailable)
        Text(
          'Questions are being restocked — not available right now.',
          style: AppTextStyles.bodyXs.copyWith(color: AppColors.danger),
        ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isSelected ? AppColors.primaryLine : AppColors.divider,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        // An empty Column reports a negative intrinsic height (its spacing is
        // subtracted once), which breaks the equal-height card row.
        child: children.isEmpty
            ? const SizedBox.shrink()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: children,
              ),
      ),
    );
  }
}

/// "×2 ELO": calibration matches move the rating twice as fast (K 64
/// instead of 32).
final class _CalibrationChip extends StatelessWidget {
  const _CalibrationChip();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          '×2 ELO',
          style: AppTextStyles.monoCaption.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.04 * 11,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}

final class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 24,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? AppColors.primary : null,
          border: isSelected
              ? null
              : Border.all(color: AppColors.borderStrong, width: 1.5),
        ),
        child: isSelected
            ? const Center(
                child: AppSvgIcon(AppIcons.check, width: 12, height: 12),
              )
            : null,
      ),
    );
  }
}
