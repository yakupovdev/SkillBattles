import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_progress_bar.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';
import 'package:skill_battles/features/account/domain/entity/calibration_entity.dart';
import 'package:skill_battles/features/account/domain/entity/discipline_stats_entity.dart';
import 'package:skill_battles/features/account/domain/entity/rank_progress_entity.dart';
import 'package:skill_battles/features/account/domain/entity/statistics_entity.dart';
import 'package:skill_battles/features/catalog/domain/entity/discipline_entity.dart';
import 'package:skill_battles/features/catalog/domain/entity/rank_ladder_entity.dart';
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
          spacing: 24,
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
            if (stats != null) _RatingRow(stats: stats, isSelected: isSelected),
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

final class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.stats, required this.isSelected});

  final DisciplineStatsEntity stats;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final RankProgressEntity rank = stats.rank;
    final int? target = rank.divisionRpTarget;
    final String progress = target == null
        ? '${rank.divisionRpCurrent} RP'
        : '${rank.divisionRpCurrent} / $target RP';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 16,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: <Widget>[
              Text(
                '${stats.rating}',
                style: AppTextStyles.monoXl.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.ink,
                ),
              ),
              Text(
                rank.rankName,
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 8,
          children: <Widget>[
            Text(
              progress,
              style: AppTextStyles.eyebrow.copyWith(letterSpacing: 0),
            ),
            SizedBox(
              width: 160,
              child: AppProgressBar(
                fraction: rank.fraction ?? 1,
                color: isSelected ? AppColors.primary : AppColors.ink,
                trackColor: isSelected
                    ? AppColors.primaryLine
                    : AppColors.divider,
              ),
            ),
          ],
        ),
      ],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: <Widget>[
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
                style: AppTextStyles.bodyXs.copyWith(
                  color: AppColors.accentText,
                ),
              ),
            if (!discipline.contentAvailable)
              Text(
                'Questions are being restocked — not available right now.',
                style: AppTextStyles.bodyXs.copyWith(color: AppColors.danger),
              ),
          ],
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
