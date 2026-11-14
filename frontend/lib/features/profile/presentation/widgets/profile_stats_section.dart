import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/features/account/domain/entity/discipline_stats_entity.dart';
import 'package:skill_battles/features/account/domain/entity/match_stats_entity.dart';
import 'package:skill_battles/features/account/domain/entity/rating_history_point_entity.dart';
import 'package:skill_battles/features/account/domain/entity/topic_stats_entity.dart';
import 'package:skill_battles/features/profile/presentation/widgets/rating_history_chart.dart';

/// `1,032`.
String _grouped(int value) {
  final String digits = value.abs().toString();
  final StringBuffer out = StringBuffer(value < 0 ? '−' : '');
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

/// Rating, ranked record, accuracy, speed and streak between two rules.
/// Basic statistics count every match on every plan.
final class ProfileKpiStrip extends StatelessWidget {
  const ProfileKpiStrip({required this.stats, super.key});

  final DisciplineStatsEntity stats;

  @override
  Widget build(BuildContext context) {
    final MatchStatsEntity ranked = stats.ranked;
    final MatchStatsEntity private = stats.privateMatches;
    final Duration? avg = ranked.avgAnswerTime;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.border),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                flex: 13,
                child: _Kpi(
                  label: 'Rating · ${stats.rank.rankName}',
                  value: _grouped(stats.rating),
                  caption: 'Peak ${_grouped(stats.allTimePeakRating)} all-time',
                  valueColor: AppColors.primary,
                  isLead: true,
                ),
              ),
              Expanded(
                flex: 10,
                child: _Kpi(
                  label: 'Ranked W–L–D',
                  value: '${ranked.wins}–${ranked.losses}–${ranked.draws}',
                  caption: ranked.winRatePercent == null
                      ? 'No ranked matches yet'
                      : '${DisplayFormatters.percent(ranked.winRatePercent)} '
                            'win rate',
                ),
              ),
              Expanded(
                flex: 10,
                child: _Kpi(
                  label: 'Accuracy',
                  value: DisplayFormatters.percent(ranked.accuracyPercent),
                  caption: 'of ${ranked.questionCount} questions',
                ),
              ),
              Expanded(
                flex: 10,
                child: _Kpi(
                  label: 'Avg answer time',
                  value: avg == null
                      ? '—'
                      : '${(avg.inMilliseconds / 1000).toStringAsFixed(1)}s',
                  caption: 'answered questions only',
                ),
              ),
              Expanded(
                flex: 10,
                child: _Kpi(
                  label: 'Win streak',
                  value: '${ranked.currentWinStreak}',
                  caption:
                      'best ${ranked.bestWinStreak} · private '
                      '${private.wins}–${private.losses}–${private.draws}',
                  valueColor: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.label,
    required this.value,
    required this.caption,
    this.valueColor = AppColors.ink,
    this.isLead = false,
  });

  final String label;
  final String value;
  final String caption;
  final Color valueColor;

  /// The first, larger value without a divider on its left.
  final bool isLead;

  @override
  Widget build(BuildContext context) {
    final TextStyle valueStyle = isLead
        ? AppTextStyles.monoXl.copyWith(
            fontSize: 40,
            height: 44 / 40,
            letterSpacing: -0.02 * 40,
          )
        : AppTextStyles.monoMd.copyWith(
            height: 44 / 28,
            fontWeight: FontWeight.w500,
          );
    final Widget column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: <Widget>[
        Text(
          label,
          style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(value, style: valueStyle.copyWith(color: valueColor)),
        Text(
          caption,
          style: AppTextStyles.bodyXs.copyWith(color: AppColors.muted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
    if (isLead) return column;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.divider)),
      ),
      child: Padding(padding: const EdgeInsets.only(left: 28), child: column),
    );
  }
}

/// Pro topic analytics and the Elo graph. `null` values mean the plan does
/// not include them — not that there is no progress — so Free sees the
/// locked panel instead.
final class ProfileAnalyticsSection extends StatelessWidget {
  const ProfileAnalyticsSection({required this.stats, super.key});

  final DisciplineStatsEntity stats;

  @override
  Widget build(BuildContext context) {
    final List<TopicStatsEntity>? topics = stats.topicStats;
    final List<RatingHistoryPointEntity>? history = stats.ratingHistory;
    if (topics == null || history == null) {
      return const Skeleton.leaf(child: ProfileLockedAnalytics());
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 56,
      children: <Widget>[
        Expanded(
          flex: 125,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: <Widget>[
              _SectionTitle(
                title: history.isEmpty
                    ? 'Elo over ranked matches'
                    : 'Elo over last ${history.length} ranked',
                note: 'Each point is a ranked result',
              ),
              RatingHistoryChart(points: history),
            ],
          ),
        ),
        Expanded(
          flex: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: <Widget>[
              const _SectionTitle(
                title: 'By topic',
                note: 'Accuracy · questions',
              ),
              if (topics.isEmpty)
                Text(
                  'Play a few matches to see your topics.',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
                )
              else
                for (final TopicStatsEntity topic in topics)
                  _TopicRow(
                    key: ValueKey<String>(topic.topicCode),
                    topic: topic,
                  ),
              Text(
                'Weak = under 65% accuracy with at least 5 questions.',
                style: AppTextStyles.bodyXs.copyWith(
                  height: 18 / 12,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.note});

  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      spacing: 12,
      children: <Widget>[
        Expanded(child: Text(title, style: AppTextStyles.titleMd)),
        Text(
          note,
          style: AppTextStyles.bodyXs.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

final class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.topic, super.key});

  final TopicStatsEntity topic;

  @override
  Widget build(BuildContext context) {
    final bool weak = topic.isWeakTopic;
    final TextStyle mono = AppTextStyles.monoBodySm.copyWith(height: 18 / 13);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: <Widget>[
          Row(
            spacing: 8,
            children: <Widget>[
              Flexible(
                child: Text(
                  topic.topicName,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: weak ? FontWeight.w600 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (weak) const _WeakChip(),
              const Spacer(),
              Text.rich(
                TextSpan(
                  text: DisplayFormatters.percent(topic.accuracyPercent),
                  children: <InlineSpan>[
                    TextSpan(
                      text: ' · ${topic.questionCount}',
                      style: mono.copyWith(color: AppColors.faint),
                    ),
                  ],
                ),
                style: mono.copyWith(
                  color: weak ? AppColors.dangerText : AppColors.ink,
                ),
              ),
            ],
          ),
          _Bar(
            fraction: topic.accuracyPercent / 100,
            color: weak ? AppColors.danger : AppColors.ink,
          ),
        ],
      ),
    );
  }
}

final class _WeakChip extends StatelessWidget {
  const _WeakChip();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.dangerSurface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          'WEAK',
          style: AppTextStyles.monoCaption.copyWith(
            fontSize: 10,
            height: 12 / 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.04 * 10,
            color: AppColors.dangerText,
          ),
        ),
      ),
    );
  }
}

/// A 6 px rounded bar on the divider track.
final class _Bar extends StatelessWidget {
  const _Bar({
    required this.fraction,
    required this.color,
    this.trackColor = AppColors.divider,
  });

  final double fraction;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(3);
    return SizedBox(
      height: 6,
      child: DecoratedBox(
        decoration: BoxDecoration(color: trackColor, borderRadius: radius),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: fraction.clamp(0, 1).toDouble(),
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, borderRadius: radius),
          ),
        ),
      ),
    );
  }
}

/// The ink "Advanced analytics" panel shown to Free readers. It says what
/// Pro adds and renders only a decorative preview, never hidden values.
final class ProfileLockedAnalytics extends StatelessWidget {
  const ProfileLockedAnalytics({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        child: Row(
          spacing: 40,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 14,
                children: <Widget>[
                  Row(
                    spacing: 8,
                    children: <Widget>[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          child: Text(
                            'PRO',
                            style: AppTextStyles.monoCaption.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.06 * 11,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        'Advanced analytics',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.onDarkSubtle,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Find your weak topics before the opponent does.',
                    style: AppTextStyles.titleXl.copyWith(
                      height: 36 / 32,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    'Accuracy for every topic across your whole history, '
                    'weak-spot flags, and an Elo graph of your last 30 ranked '
                    'matches. Your progress is already being tracked — Pro '
                    'just shows it.',
                    style: AppTextStyles.bodyLg.copyWith(
                      height: 22 / 15,
                      color: AppColors.onDarkMuted,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: AppButton(
                      label: 'See plans',
                      variant: AppButtonVariant.accent,
                      size: AppButtonSize.medium,
                      onPressed: context.goPro,
                    ),
                  ),
                ],
              ),
            ),
            const _LockedPreview(),
          ],
        ),
      ),
    );
  }
}

final class _LockedPreview extends StatelessWidget {
  const _LockedPreview();

  @override
  Widget build(BuildContext context) {
    final Color label = AppColors.white.withValues(alpha: 0.2);
    final Color track = AppColors.white.withValues(alpha: 0.1);
    final Color fill = AppColors.white.withValues(alpha: 0.3);
    return ExcludeSemantics(
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: track),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: <Widget>[
            for (final (double width, double fraction, Color color)
                in <(double, double, Color)>[
                  (140, 0.8, fill),
                  (100, 0.64, fill),
                  (120, 0.52, AppColors.accent.withValues(alpha: 0.6)),
                ])
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: <Widget>[
                  Container(
                    width: width,
                    height: 10,
                    decoration: BoxDecoration(
                      color: label,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  _Bar(fraction: fraction, color: color, trackColor: track),
                ],
              ),
            SizedBox(
              height: 70,
              child: CustomPaint(painter: _PreviewLinePainter(color: fill)),
            ),
            Text(
              'Preview · unlocks with Pro',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyXs.copyWith(
                color: AppColors.onDarkFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _PreviewLinePainter extends CustomPainter {
  const _PreviewLinePainter({required this.color});

  final Color color;

  /// The Paper polyline, normalized to its 410 × 70 box.
  static const List<Offset> _points = <Offset>[
    Offset(0, 50),
    Offset(40, 44),
    Offset(80, 52),
    Offset(120, 36),
    Offset(160, 40),
    Offset(200, 28),
    Offset(240, 34),
    Offset(280, 22),
    Offset(320, 30),
    Offset(360, 18),
    Offset(410, 14),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path();
    for (int i = 0; i < _points.length; i++) {
      final Offset p = Offset(
        _points[i].dx / 410 * size.width,
        _points[i].dy / 70 * size.height,
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_PreviewLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
