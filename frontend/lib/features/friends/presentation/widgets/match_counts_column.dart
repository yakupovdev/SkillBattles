import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/match_stats_entity.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';

/// One column of a friend's match counters (`RANKED` or `PRIVATE`): label
/// rows on the left, mono values on the right. Values the server could not
/// compute (win rate, accuracy and answer time of zero matches) read `—`.
final class MatchCountsColumn extends StatelessWidget {
  const MatchCountsColumn({
    required this.title,
    required this.stats,
    super.key,
  });

  final String title;
  final MatchStatsEntity stats;

  @override
  Widget build(BuildContext context) {
    final Duration? avg = stats.avgAnswerTime;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: <Widget>[
        Skeleton.keep(child: AppEyebrow(title)),
        _CountRow(
          label: 'W–L–D',
          value: '${stats.wins}–${stats.losses}–${stats.draws}',
        ),
        _CountRow(label: 'Played', value: '${stats.played}'),
        _CountRow(
          label: 'Win rate',
          value: stats.winRatePercent == null
              ? null
              : DisplayFormatters.percent(stats.winRatePercent),
        ),
        _CountRow(
          label: 'Win streak · best',
          value: '${stats.currentWinStreak} · ${stats.bestWinStreak}',
        ),
        _CountRow(
          label: 'Accuracy',
          value: stats.accuracyPercent == null
              ? null
              : DisplayFormatters.percent(stats.accuracyPercent),
        ),
        _CountRow(
          label: 'Avg answer time',
          value: avg == null
              ? null
              : '${(avg.inMilliseconds / 1000).toStringAsFixed(1)}s',
        ),
      ],
    );
  }
}

/// A label and its value; a `null` [value] is drawn as a faint `—`.
final class _CountRow extends StatelessWidget {
  const _CountRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final String? text = value;
    return Row(
      spacing: 12,
      children: <Widget>[
        Expanded(
          child: Skeleton.keep(
            child: Text(
              label,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.muted),
            ),
          ),
        ),
        Text(
          text ?? '—',
          style: AppTextStyles.monoBodyMd.copyWith(
            color: text == null ? AppColors.faint : AppColors.ink,
          ),
          textAlign: TextAlign.end,
        ),
      ],
    );
  }
}
