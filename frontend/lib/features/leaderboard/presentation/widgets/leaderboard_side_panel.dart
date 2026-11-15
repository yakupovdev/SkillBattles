import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/app/theme/league_colors.dart';
import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/league/league_rank.dart';
import 'package:skill_battles/core/presentation/widgets/app_progress_bar.dart';
import 'package:skill_battles/core/presentation/widgets/league_emblem.dart';
import 'package:skill_battles/features/account/domain/entity/discipline_stats_entity.dart';
import 'package:skill_battles/features/account/domain/entity/rank_progress_entity.dart';
import 'package:skill_battles/features/account/domain/entity/season_peak_entity.dart';
import 'package:skill_battles/features/catalog/domain/entity/discipline_entity.dart';
import 'package:skill_battles/features/catalog/presentation/extensions/catalog_labels.dart';
import 'package:skill_battles/features/catalog/presentation/extensions/discipline_short_name.dart';
import 'package:skill_battles/features/leaderboard/domain/entity/leaderboard_entity.dart';

/// The right column: the own position and peaks, past seasons and how the
/// ranking works.
final class LeaderboardSidePanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final int? position = board.me?.position;
    final DisciplineStatsEntity? stats = this.stats;
    final TextStyle muted = AppTextStyles.bodySm.copyWith(
      color: AppColors.muted,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 28,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: <Widget>[
            Text(
              'Your position · ${disciplines.nameOf(board.disciplineCode)}',
              style: muted,
            ),
            Text(
              position == null ? '—' : '#$position',
              style: AppTextStyles.monoXl.copyWith(
                fontSize: 48,
                height: 52 / 48,
                letterSpacing: -0.02 * 48,
                color: AppColors.primary,
              ),
            ),
            Text(
              position == null
                  ? 'You appear here once your season rating is ready.'
                  : stats == null
                  ? 'Season ${board.season.name}'
                  : 'Season peak '
                        '${DisplayFormatters.grouped(stats.seasonPeakRating)} · '
                        'All-time peak '
                        '${DisplayFormatters.grouped(stats.allTimePeakRating)}',
              style: muted.copyWith(height: 19 / 13),
            ),
            if (stats != null) _SidebarLeague(rank: stats.rank),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 4,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Past seasons', style: AppTextStyles.titleMd),
            ),
            if (seasons.isEmpty)
              Text('No finished seasons yet.', style: muted)
            else
              for (final SeasonPeakEntity season in seasons)
                _SeasonRow(
                  season: season,
                  disciplineName: disciplines.shortNameOf(
                    season.disciplineCode,
                  ),
                ),
          ],
        ),
        Text(
          'Ranked by Elo, then by who reached it first. Ratings get a soft '
          'reset toward 1000 when a new season starts on '
          '${DisplayFormatters.etBoundaryDay(board.season.endsAt)}.',
          style: muted.copyWith(height: 20 / 13),
        ),
      ],
    );
  }
}

/// The own league: emblem, rank name and RP progress inside the tier.
final class _SidebarLeague extends StatelessWidget {
  const _SidebarLeague({required this.rank});

  final RankProgressEntity rank;

  @override
  Widget build(BuildContext context) {
    final LeagueRank? league = LeagueRank.tryParse(rank.rankCode);
    final LeaguePalette? palette = league == null
        ? null
        : LeagueColors.of(league.league);
    final int? target = rank.divisionRpTarget;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette?.tint ?? AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          spacing: 14,
          children: <Widget>[
            if (league != null) LeagueEmblem(rank: league, size: 52),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 6,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    spacing: 8,
                    children: <Widget>[
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            rank.rankName,
                            style: AppTextStyles.titleSm.copyWith(
                              color: palette?.nameText,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ),
                      Text(
                        target == null
                            ? 'Open tier'
                            : '${rank.divisionRpCurrent} / $target RP',
                        style: AppTextStyles.eyebrow.copyWith(
                          letterSpacing: 0,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  if (target != null)
                    Skeleton.leaf(
                      child: AppProgressBar(
                        fraction: rank.fraction ?? 1,
                        color: palette?.deep ?? AppColors.ink,
                        trackColor: AppColors.border,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _SeasonRow extends StatelessWidget {
  const _SeasonRow({required this.season, required this.disciplineName});

  final SeasonPeakEntity season;
  final String disciplineName;

  @override
  Widget build(BuildContext context) {
    final TextStyle meta = AppTextStyles.bodyXs.copyWith(
      color: AppColors.muted,
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          spacing: 12,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: <Widget>[
                  Text(season.season.name, style: AppTextStyles.buttonMd),
                  Text(
                    '$disciplineName · finished at '
                    '${DisplayFormatters.grouped(season.finalRating)}',
                    style: meta,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 2,
              children: <Widget>[
                Text(
                  DisplayFormatters.grouped(season.peakRating),
                  style: AppTextStyles.monoBodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Peak · ${formatRankCode(season.peakRankCode)}',
                  style: meta,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
