import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/match_stats_entity.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/skeleton/skeletonizer.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';

/// One column of a friend's match counters (`RANKED` or `PRIVATE`): label
/// rows on the left, mono values on the right. Values the server could not
/// compute (win rate, accuracy and answer time of zero matches) read `—`.
final class MatchCountsColumn extends StatelessComponent {
  const MatchCountsColumn({
    required this.title,
    required this.stats,
    super.key,
  });

  final String title;
  final MatchStatsEntity stats;

  @override
  Component build(BuildContext context) {
    final Duration? avg = stats.avgAnswerTime;
    return div(classes: 'match-counts-column', <Component>[
      Skeleton.keep(child: AppEyebrow(title)),
      _CountRow(label: 'W–L–D', value: '${stats.wins}–${stats.losses}–${stats.draws}'),
      _CountRow(label: 'Played', value: '${stats.played}'),
      _CountRow(
        label: 'Win rate',
        value: stats.winRatePercent == null ? null : DisplayFormatters.percent(stats.winRatePercent),
      ),
      _CountRow(label: 'Win streak · best', value: '${stats.currentWinStreak} · ${stats.bestWinStreak}'),
      _CountRow(
        label: 'Accuracy',
        value: stats.accuracyPercent == null ? null : DisplayFormatters.percent(stats.accuracyPercent),
      ),
      _CountRow(
        label: 'Avg answer time',
        value: avg == null ? null : '${(avg.inMilliseconds / 1000).toStringAsFixed(1)}s',
      ),
    ]);
  }
}

/// A label and its value; a `null` [value] is drawn as a faint `—`.
final class _CountRow extends StatelessComponent {
  const _CountRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Component build(BuildContext context) {
    final String? text = value;
    return div(classes: 'match-counts-column__row', <Component>[
      Skeleton.keep(
        child: span(classes: 'match-counts-column__label', <Component>[Component.text(label)]),
      ),
      span(
        classes: text == null
            ? 'match-counts-column__value match-counts-column__value--empty'
            : 'match-counts-column__value',
        <Component>[Component.text(text ?? '—')],
      ),
    ]);
  }
}

@css
List<StyleRule> get matchCountsColumnStyles => <StyleRule>[
  css('.match-counts-column').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(10)),
  ),
  css('.match-counts-column__row').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(12)),
  ),
  css('.match-counts-column__label')
      .styles(
        minWidth: Unit.zero,
        flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
      )
      .combine(AppTextStyles.bodyMd)
      .combine(const Styles(color: AppColors.muted)),
  css('.match-counts-column__value')
      .styles(textAlign: TextAlign.end)
      .combine(AppTextStyles.monoBodyMd)
      .combine(const Styles(color: AppColors.ink)),
  css('.match-counts-column__value--empty').styles(color: AppColors.faint),
];
