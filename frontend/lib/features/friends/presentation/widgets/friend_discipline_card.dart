import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/app/theme/league_colors.dart';
import 'package:skill_battles/core/domain/entity/calibration_entity.dart';
import 'package:skill_battles/core/domain/entity/rank_progress_entity.dart';
import 'package:skill_battles/core/presentation/league/league_rank.dart';
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
final class FriendDisciplineCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final LeagueRank? league = LeagueRank.tryParse(stats.rank.rankCode);
    return AppCard(
      color: AppColors.white,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 24,
        children: <Widget>[
          _Head(name: disciplineName, calibration: stats.calibration),
          if (stats.seasonRolloverPending)
            const Skeleton.ignore(
              child: AppNotice(
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
        ],
      ),
    );
  }
}

final class _Head extends StatelessWidget {
  const _Head({required this.name, required this.calibration});

  final String name;
  final CalibrationEntity calibration;

  @override
  Widget build(BuildContext context) {
    final TextStyle status = AppTextStyles.bodySm;
    return Row(
      spacing: 12,
      children: <Widget>[
        Expanded(
          child: Text(
            name,
            style: AppTextStyles.titleXlCompact,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (calibration.isCalibrating)
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: <Widget>[
                const _CalibrationChip(),
                Flexible(
                  child: Text(
                    'Calibrating · ${calibration.matchesRemaining} of '
                    '${calibration.completedMatches + calibration.matchesRemaining}'
                    ' matches left',
                    style: status.copyWith(color: AppColors.primaryInk),
                  ),
                ),
              ],
            ),
          )
        else
          Text('Calibrated', style: status.copyWith(color: AppColors.muted)),
      ],
    );
  }
}

/// "×2 ELO", the same chip as the home discipline cards.
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

final class _LeagueHero extends StatelessWidget {
  const _LeagueHero({
    required this.rank,
    required this.rating,
    required this.league,
  });

  final RankProgressEntity rank;
  final int rating;
  final LeagueRank? league;

  @override
  Widget build(BuildContext context) {
    final LeagueRank? current = league;
    final LeaguePalette? palette = current == null
        ? null
        : LeagueColors.of(current.league);
    return Row(
      spacing: 16,
      children: <Widget>[
        if (current != null && palette != null)
          Skeleton.leaf(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.tint,
                border: Border.all(color: palette.base),
              ),
              child: SizedBox.square(
                dimension: 88,
                child: Center(child: LeagueEmblem(rank: current, size: 72)),
              ),
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: <Widget>[
              Skeleton.keep(
                child: Text(
                  'LEAGUE',
                  style: AppTextStyles.monoCaption.copyWith(
                    letterSpacing: 0.1 * 11,
                    color: AppColors.muted,
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  rank.rankName,
                  style: AppTextStyles.titleXl.copyWith(
                    fontSize: 30,
                    height: 34 / 30,
                    letterSpacing: -0.02 * 30,
                    color: palette?.nameText,
                  ),
                  maxLines: 1,
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
              '$rating',
              style: AppTextStyles.monoXl.copyWith(
                fontSize: 28,
                height: 32 / 28,
                letterSpacing: -0.02 * 28,
              ),
            ),
            Skeleton.keep(
              child: Text(
                'Elo rating',
                style: AppTextStyles.bodyXs.copyWith(color: AppColors.muted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

final class _DivisionProgress extends StatelessWidget {
  const _DivisionProgress({required this.rank, required this.league});

  final RankProgressEntity rank;
  final LeagueRank? league;

  @override
  Widget build(BuildContext context) {
    final int? target = rank.divisionRpTarget;
    final LeagueRank? current = league;
    final Color fill = current == null
        ? AppColors.ink
        : LeagueColors.of(current.league).deep;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: <Widget>[
        Text(
          target == null
              ? 'Open tier · no RP cap'
              : '${rank.divisionRpCurrent} / $target RP',
          style: AppTextStyles.eyebrow.copyWith(
            letterSpacing: 0,
            color: AppColors.inkSoft,
          ),
        ),
        if (target != null)
          Skeleton.leaf(
            child: AppProgressBar(
              fraction: rank.fraction ?? 1,
              color: fill,
              trackColor: AppColors.divider,
              height: 8,
            ),
          ),
      ],
    );
  }
}

final class _Peaks extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return _Section(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 24,
        children: <Widget>[
          Expanded(
            child: _Peak(
              label: 'All-time peak',
              rating: allTimeRating,
              rankName: allTimeRank,
            ),
          ),
          Expanded(
            child: _Peak(
              label: 'Season peak',
              rating: seasonRating,
              rankName: seasonRank,
            ),
          ),
        ],
      ),
    );
  }
}

final class _Peak extends StatelessWidget {
  const _Peak({
    required this.label,
    required this.rating,
    required this.rankName,
  });

  final String label;
  final int rating;
  final String rankName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: <Widget>[
        Skeleton.keep(
          child: Text(
            label,
            style: AppTextStyles.bodyXs.copyWith(color: AppColors.muted),
          ),
        ),
        Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(
                text: '$rating',
                style: AppTextStyles.monoBodyMd.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(text: ' · $rankName'),
            ],
          ),
          style: AppTextStyles.bodyLg,
        ),
      ],
    );
  }
}

final class _Counters extends StatelessWidget {
  const _Counters({required this.stats});

  final FriendDisciplineStatsEntity stats;

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 24,
          children: <Widget>[
            Expanded(
              child: MatchCountsColumn(title: 'RANKED', stats: stats.ranked),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppColors.divider,
            ),
            Expanded(
              child: MatchCountsColumn(
                title: 'PRIVATE',
                stats: stats.privateMatches,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A block below a 1 px divider.
final class _Section extends StatelessWidget {
  const _Section({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Padding(padding: const EdgeInsets.only(top: 16), child: child),
    );
  }
}
