import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/match_stats_entity.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/skeleton/skeletonizer.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/features/account/domain/entity/discipline_stats_entity.dart';
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
final class ProfileKpiStrip extends StatelessComponent {
  const ProfileKpiStrip({required this.stats, super.key});

  final DisciplineStatsEntity stats;

  @override
  Component build(BuildContext context) {
    final MatchStatsEntity ranked = stats.ranked;
    final MatchStatsEntity private = stats.privateMatches;
    final Duration? avg = ranked.avgAnswerTime;
    return div(classes: 'profile-kpis', <Component>[
      _Kpi(
        flex: 13,
        label: 'Rating · ${stats.rank.rankName}',
        value: _grouped(stats.rating),
        caption: 'Peak ${_grouped(stats.allTimePeakRating)} all-time',
        valueColor: AppColors.primary,
        isLead: true,
      ),
      _Kpi(
        flex: 10,
        label: 'Ranked W–L–D',
        value: '${ranked.wins}–${ranked.losses}–${ranked.draws}',
        caption: ranked.winRatePercent == null
            ? 'No ranked matches yet'
            : '${DisplayFormatters.percent(ranked.winRatePercent)} win rate',
      ),
      _Kpi(
        flex: 10,
        label: 'Accuracy',
        value: DisplayFormatters.percent(ranked.accuracyPercent),
        caption: 'of ${ranked.questionCount} questions',
      ),
      _Kpi(
        flex: 10,
        label: 'Avg answer time',
        value: avg == null ? '—' : '${(avg.inMilliseconds / 1000).toStringAsFixed(1)}s',
        caption: 'answered questions only',
      ),
      _Kpi(
        flex: 10,
        label: 'Win streak',
        value: '${ranked.currentWinStreak}',
        caption:
            'best ${ranked.bestWinStreak} · private '
            '${private.wins}–${private.losses}–${private.draws}',
        valueColor: AppColors.accent,
      ),
    ]);
  }
}

final class _Kpi extends StatelessComponent {
  const _Kpi({
    required this.flex,
    required this.label,
    required this.value,
    required this.caption,
    this.valueColor = AppColors.ink,
    this.isLead = false,
  });

  /// Share of the strip width.
  final double flex;
  final String label;
  final String value;
  final String caption;
  final Color valueColor;

  /// The first, larger value without a divider on its left.
  final bool isLead;

  @override
  Component build(BuildContext context) {
    return div(
      classes: isLead ? 'profile-kpi' : 'profile-kpi profile-kpi--divided',
      styles: Styles(
        flex: Flex(grow: flex, shrink: 1, basis: Unit.zero),
      ),
      <Component>[
        span(classes: 'profile-kpi__label', <Component>[Component.text(label)]),
        span(
          classes: isLead ? 'profile-kpi__value profile-kpi__value--lead' : 'profile-kpi__value',
          styles: Styles(color: valueColor),
          <Component>[Component.text(value)],
        ),
        span(classes: 'profile-kpi__caption', <Component>[Component.text(caption)]),
      ],
    );
  }
}

/// Pro topic analytics and the Elo graph. `null` values mean the plan does
/// not include them — not that there is no progress — so Free sees the
/// locked panel instead.
final class ProfileAnalyticsSection extends StatelessComponent {
  const ProfileAnalyticsSection({required this.stats, super.key});

  final DisciplineStatsEntity stats;

  @override
  Component build(BuildContext context) {
    final List<TopicStatsEntity>? topics = stats.topicStats;
    final List<RatingHistoryPointEntity>? history = stats.ratingHistory;
    if (topics == null || history == null) {
      return Skeleton.leaf(child: const ProfileLockedAnalytics());
    }
    return div(classes: 'profile-analytics', <Component>[
      div(classes: 'profile-analytics__elo', <Component>[
        _SectionTitle(
          title: history.isEmpty ? 'Elo over ranked matches' : 'Elo over last ${history.length} ranked',
          note: 'Each point is a ranked result',
        ),
        RatingHistoryChart(points: history),
      ]),
      div(classes: 'profile-analytics__topics', <Component>[
        const _SectionTitle(title: 'By topic', note: 'Accuracy · questions'),
        if (topics.isEmpty)
          const p(classes: 'profile-analytics__empty', <Component>[
            Component.text('Play a few matches to see your topics.'),
          ])
        else
          for (final TopicStatsEntity topic in topics) _TopicRow(key: ValueKey<String>(topic.topicCode), topic: topic),
        const p(classes: 'profile-analytics__note', <Component>[
          Component.text('Weak = under 65% accuracy with at least 5 questions.'),
        ]),
      ]),
    ]);
  }
}

final class _SectionTitle extends StatelessComponent {
  const _SectionTitle({required this.title, required this.note});

  final String title;
  final String note;

  @override
  Component build(BuildContext context) {
    return div(classes: 'profile-section-title', <Component>[
      h2(classes: 'profile-section-title__title', <Component>[Component.text(title)]),
      span(classes: 'profile-section-title__note', <Component>[Component.text(note)]),
    ]);
  }
}

final class _TopicRow extends StatelessComponent {
  const _TopicRow({required this.topic, super.key});

  final TopicStatsEntity topic;

  @override
  Component build(BuildContext context) {
    final bool weak = topic.isWeakTopic;
    return div(classes: 'profile-topic', <Component>[
      div(classes: 'profile-topic__head', <Component>[
        span(
          classes: weak ? 'profile-topic__name profile-topic__name--weak' : 'profile-topic__name',
          <Component>[Component.text(topic.topicName)],
        ),
        if (weak) const _WeakChip(),
        span(classes: weak ? 'profile-topic__value profile-topic__value--weak' : 'profile-topic__value', <Component>[
          Component.text(DisplayFormatters.percent(topic.accuracyPercent)),
          span(classes: 'profile-topic__count', <Component>[Component.text(' · ${topic.questionCount}')]),
        ]),
      ]),
      _Bar(fraction: topic.accuracyPercent / 100, color: weak ? AppColors.danger : AppColors.ink),
    ]);
  }
}

final class _WeakChip extends StatelessComponent {
  const _WeakChip();

  @override
  Component build(BuildContext context) {
    return const span(classes: 'profile-weak-chip', <Component>[Component.text('WEAK')]);
  }
}

/// A 6 px rounded bar on the divider track.
final class _Bar extends StatelessComponent {
  const _Bar({required this.fraction, required this.color, this.trackColor = AppColors.divider});

  final double fraction;
  final Color color;
  final Color trackColor;

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'profile-bar',
      styles: Styles(backgroundColor: trackColor),
      <Component>[
        div(
          classes: 'profile-bar__fill',
          styles: Styles(
            width: Unit.percent(fraction.clamp(0, 1).toDouble() * 100),
            backgroundColor: color,
          ),
          const <Component>[],
        ),
      ],
    );
  }
}

/// The ink "Advanced analytics" panel shown to Free readers. It says what
/// Pro adds and renders only a decorative preview, never hidden values.
final class ProfileLockedAnalytics extends StatelessComponent {
  const ProfileLockedAnalytics({super.key});

  @override
  Component build(BuildContext context) {
    return div(classes: 'profile-locked', <Component>[
      div(classes: 'profile-locked__copy', <Component>[
        const div(classes: 'profile-locked__eyebrow', <Component>[
          span(classes: 'profile-locked__pro', <Component>[Component.text('PRO')]),
          span(classes: 'profile-locked__eyebrow-text', <Component>[Component.text('Advanced analytics')]),
        ]),
        const h2(classes: 'profile-locked__title', <Component>[
          Component.text('Find your weak topics before the opponent does.'),
        ]),
        const p(classes: 'profile-locked__body', <Component>[
          Component.text(
            'Accuracy for every topic across your whole history, '
            'weak-spot flags, and an Elo graph of your last 30 ranked '
            'matches. Your progress is already being tracked — Pro '
            'just shows it.',
          ),
        ]),
        div(classes: 'profile-locked__action', <Component>[
          AppButton(
            label: 'See plans',
            variant: AppButtonVariant.accent,
            size: AppButtonSize.medium,
            onPressed: context.goPro,
          ),
        ]),
      ]),
      const _LockedPreview(),
    ]);
  }
}

final class _LockedPreview extends StatelessComponent {
  const _LockedPreview();

  static const Color _label = Color.rgba(255, 255, 255, 0.2);
  static const Color _track = Color.rgba(255, 255, 255, 0.1);
  static const Color _fill = Color.rgba(255, 255, 255, 0.3);

  /// [AppColors.accent] at 60 %.
  static const Color _accentFill = Color.rgba(245, 165, 36, 0.6);

  /// The Paper polyline in its 410 × 70 box.
  static const String _line = '0,50 40,44 80,52 120,36 160,40 200,28 240,34 280,22 320,30 360,18 410,14';

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'profile-locked__preview',
      attributes: const <String, String>{'aria-hidden': 'true'},
      <Component>[
        for (final (double width, double fraction, Color color) in const <(double, double, Color)>[
          (140, 0.8, _fill),
          (100, 0.64, _fill),
          (120, 0.52, _accentFill),
        ])
          div(classes: 'profile-locked__preview-row', <Component>[
            div(
              classes: 'profile-locked__preview-label',
              styles: Styles(width: Unit.pixels(width), backgroundColor: _label),
              const <Component>[],
            ),
            _Bar(fraction: fraction, color: color, trackColor: _track),
          ]),
        svg(
          classes: 'profile-locked__preview-line',
          viewBox: '0 0 410 70',
          attributes: const <String, String>{'preserveAspectRatio': 'none'},
          <Component>[
            polyline(
              points: _line,
              stroke: _fill,
              strokeWidth: '2',
              attributes: const <String, String>{
                'fill': 'none',
                'vector-effect': 'non-scaling-stroke',
                'stroke-linejoin': 'round',
              },
              const <Component>[],
            ),
          ],
        ),
        const p(classes: 'profile-locked__preview-caption', <Component>[Component.text('Preview · unlocks with Pro')]),
      ],
    );
  }
}

@css
List<StyleRule> get profileStatsSectionStyles => <StyleRule>[
  css('.profile-kpis').styles(
    display: Display.flex,
    padding: const Padding.symmetric(vertical: Unit.pixels(24)),
    border: const Border.symmetric(
      horizontal: BorderSide(color: AppColors.border, width: Unit.pixels(1)),
    ),
    alignItems: AlignItems.stretch,
  ),
  css('.profile-kpi').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(4)),
  ),
  css('.profile-kpi--divided').styles(
    padding: const Padding.only(left: Unit.pixels(28)),
    border: const Border.only(
      left: BorderSide(color: AppColors.divider, width: Unit.pixels(1)),
    ),
  ),
  css('.profile-kpi__label, .profile-kpi__caption').styles(
    maxWidth: const Unit.percent(100),
    overflow: Overflow.hidden,
    textOverflow: TextOverflow.ellipsis,
    whiteSpace: WhiteSpace.noWrap,
  ),
  css('.profile-kpi__label').combine(AppTextStyles.bodySm).combine(const Styles(color: AppColors.muted)),
  css('.profile-kpi__caption').combine(AppTextStyles.bodyXs).combine(const Styles(color: AppColors.muted)),
  css('.profile-kpi__value')
      .combine(AppTextStyles.monoMd)
      .combine(const Styles(fontWeight: FontWeight.w500, lineHeight: Unit.pixels(44))),
  css('.profile-kpi__value--lead')
      .combine(AppTextStyles.monoXl)
      .combine(const Styles(fontSize: Unit.pixels(40), letterSpacing: Unit.em(-0.02), lineHeight: Unit.pixels(44))),
  css('.profile-analytics').styles(
    display: Display.flex,
    alignItems: AlignItems.start,
    gap: const Gap.column(Unit.pixels(56)),
  ),
  css('.profile-analytics__elo').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(16)),
    flex: const Flex(grow: 125, shrink: 1, basis: Unit.zero),
  ),
  css('.profile-analytics__topics').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(14)),
    flex: const Flex(grow: 100, shrink: 1, basis: Unit.zero),
  ),
  css('.profile-analytics__empty').combine(AppTextStyles.bodySm).combine(const Styles(color: AppColors.muted)),
  css('.profile-analytics__note')
      .combine(AppTextStyles.bodyXs)
      .combine(const Styles(color: AppColors.muted, lineHeight: Unit.pixels(18))),
  css('.profile-section-title').styles(
    display: Display.flex,
    alignItems: AlignItems.baseline,
    gap: const Gap.column(Unit.pixels(12)),
  ),
  css('.profile-section-title__title')
      .styles(
        minWidth: Unit.zero,
        flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
      )
      .combine(AppTextStyles.titleMd),
  css('.profile-section-title__note').combine(AppTextStyles.bodyXs).combine(const Styles(color: AppColors.muted)),
  css('.profile-topic').styles(
    display: Display.flex,
    padding: const Padding.symmetric(vertical: Unit.pixels(8)),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(6)),
  ),
  css('.profile-topic__head').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(8)),
  ),
  css('.profile-topic__name')
      .styles(
        minWidth: Unit.zero,
        overflow: Overflow.hidden,
        flex: const Flex(grow: 0, shrink: 1, basis: Unit.auto),
        textOverflow: TextOverflow.ellipsis,
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.bodyMd)
      .combine(const Styles(fontWeight: FontWeight.w500)),
  css('.profile-topic__name--weak').styles(fontWeight: FontWeight.w600),
  css('.profile-topic__value')
      .styles(
        margin: const Margin.only(left: Unit.auto),
        flex: const Flex(shrink: 0),
      )
      .combine(AppTextStyles.monoBodySm)
      .combine(const Styles(color: AppColors.ink, lineHeight: Unit.pixels(18), whiteSpace: WhiteSpace.noWrap)),
  css('.profile-topic__value--weak').styles(color: AppColors.dangerText),
  css('.profile-topic__count').styles(color: AppColors.faint),
  css('.profile-weak-chip')
      .styles(
        padding: const Padding.symmetric(horizontal: Unit.pixels(6), vertical: Unit.pixels(2)),
        radius: const BorderRadius.circular(Unit.pixels(4)),
        flex: const Flex(shrink: 0),
      )
      .combine(AppTextStyles.monoCaption)
      .combine(
        const Styles(
          color: AppColors.dangerText,
          fontSize: Unit.pixels(10),
          fontWeight: FontWeight.w700,
          letterSpacing: Unit.em(0.04),
          lineHeight: Unit.pixels(12),
          backgroundColor: AppColors.dangerSurface,
        ),
      ),
  css('.profile-bar').styles(
    height: const Unit.pixels(6),
    radius: const BorderRadius.circular(Unit.pixels(3)),
    overflow: Overflow.hidden,
  ),
  css('.profile-bar__fill').styles(
    height: const Unit.percent(100),
    radius: const BorderRadius.circular(Unit.pixels(3)),
  ),
  css('.profile-locked').styles(
    display: Display.flex,
    padding: const Padding.symmetric(horizontal: Unit.pixels(40), vertical: Unit.pixels(36)),
    radius: const BorderRadius.circular(Unit.pixels(20)),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(40)),
    backgroundColor: AppColors.ink,
  ),
  css('.profile-locked__copy').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(14)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.profile-locked__eyebrow').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(8)),
  ),
  css('.profile-locked__pro')
      .styles(
        padding: const Padding.symmetric(horizontal: Unit.pixels(8), vertical: Unit.pixels(3)),
        radius: const BorderRadius.circular(Unit.pixels(6)),
      )
      .combine(AppTextStyles.monoCaption)
      .combine(
        const Styles(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          letterSpacing: Unit.em(0.06),
          backgroundColor: AppColors.accent,
        ),
      ),
  css('.profile-locked__eyebrow-text')
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.onDarkSubtle)),
  css('.profile-locked__title')
      .combine(AppTextStyles.titleXl)
      .combine(const Styles(color: AppColors.white, lineHeight: Unit.pixels(36))),
  css('.profile-locked__body')
      .combine(AppTextStyles.bodyLg)
      .combine(const Styles(color: AppColors.onDarkMuted, lineHeight: Unit.pixels(22))),
  css('.profile-locked__action').styles(padding: const Padding.only(top: Unit.pixels(6))),
  css('.profile-locked__preview').styles(
    display: Display.flex,
    width: const Unit.pixels(460),
    padding: const Padding.all(Unit.pixels(24)),
    border: Border.all(color: const Color.rgba(255, 255, 255, 0.1), width: const Unit.pixels(1)),
    radius: const BorderRadius.circular(Unit.pixels(14)),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(14)),
    flex: const Flex(shrink: 0),
    backgroundColor: const Color.rgba(255, 255, 255, 0.05),
  ),
  css('.profile-locked__preview-row').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(6)),
  ),
  css('.profile-locked__preview-label').styles(
    height: const Unit.pixels(10),
    radius: const BorderRadius.circular(Unit.pixels(5)),
  ),
  css('.profile-locked__preview-line').styles(
    width: const Unit.percent(100),
    height: const Unit.pixels(70),
    overflow: Overflow.visible,
  ),
  css('.profile-locked__preview-caption')
      .combine(AppTextStyles.bodyXs)
      .combine(const Styles(color: AppColors.onDarkFaint, textAlign: TextAlign.center)),
];
