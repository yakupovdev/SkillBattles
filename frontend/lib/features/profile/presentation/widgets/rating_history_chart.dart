import 'dart:math' as math;

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';
import 'package:skill_battles/features/account/domain/entity/rating_history_point_entity.dart';

/// Pro line chart of the last settled ranked results (Paper: "21 Stats
/// (Pro)"). Season resets get no artificial points: the line simply jumps
/// across a dashed season divider.
///
/// Drawn as an inline SVG stretched horizontally over the plot width
/// (strokes keep their width with `vector-effect: non-scaling-stroke`);
/// the labels and the end dot are HTML placed over it, so text and circles
/// never stretch.
final class RatingHistoryChart extends StatelessComponent {
  const RatingHistoryChart({required this.points, super.key});

  /// Newest first or oldest first; drawn by `finishedAt`.
  final List<RatingHistoryPointEntity> points;

  @override
  Component build(BuildContext context) {
    if (points.isEmpty) {
      return const p(classes: 'rating-chart__empty', <Component>[
        Component.text('Play ranked matches to draw your rating graph.'),
      ]);
    }
    final List<RatingHistoryPointEntity> sorted = <RatingHistoryPointEntity>[...points]
      ..sort((RatingHistoryPointEntity a, RatingHistoryPointEntity b) => a.finishedAt.compareTo(b.finishedAt));
    final int first = sorted.first.ratingBefore;
    final int last = sorted.last.ratingAfter;
    return _Chart(
      points: sorted,
      now: DateTime.now(),
      label: 'Rating graph of the last ${sorted.length} ranked matches, from $first to $last',
    );
  }
}

final class _Chart extends StatelessComponent {
  const _Chart({required this.points, required this.now, required this.label});

  /// Oldest first.
  final List<RatingHistoryPointEntity> points;
  final DateTime now;
  final String label;

  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const double _height = 230;

  /// Space for the grid labels on the right.
  static const double _labelWidth = 40;
  static const double _gridTop = 40;

  /// The grid ends 50 px above the bottom; the date labels sit below it.
  static const double _gridBottomInset = 50;

  /// Width of the SVG coordinate system; it is stretched to the plot width.
  static const double _plotUnits = 1000;

  String _day(DateTime value) {
    final DateTime local = value.toLocal();
    final DateTime today = now.toLocal();
    if (local.year == today.year && local.month == today.month && local.day == today.day) {
      return 'Today';
    }
    return '${_months[local.month - 1]} ${local.day}';
  }

  /// Left offset of the plot fraction [fraction] (0–1), plus [extra] px.
  static Unit _left(double fraction, [double extra = 0]) =>
      Unit.expression('calc((100% - ${_labelWidth}px) * $fraction + ${extra}px)');

  static String _n(double value) => value.toStringAsFixed(2);

  @override
  Component build(BuildContext context) {
    final List<int> values = <int>[
      points.first.ratingBefore,
      for (final RatingHistoryPointEntity point in points) point.ratingAfter,
    ];
    final int minValue = values.reduce(math.min);
    final int maxValue = values.reduce(math.max);
    // Grid lines on round hundreds that enclose the data, at least two
    // steps apart.
    final int step = 100 * math.max(1, ((maxValue - minValue) / 300).ceil());
    final int low = (minValue / step).floor() * step;
    int high = (maxValue / step).ceil() * step;
    if (high - low < 2 * step) high = low + 2 * step;

    const double gridBottom = _height - _gridBottomInset;
    double yOf(num value) => gridBottom - (value - low) / (high - low) * (gridBottom - _gridTop);
    double fractionOf(int index) => values.length == 1 ? 0 : index / (values.length - 1);

    final List<int> gridValues = <int>[for (int value = low; value <= high; value += step) value];
    // Season dividers between the last match of a season and the first of
    // the next one.
    final List<(double, String)> seasons = <(double, String)>[
      for (int i = 1; i < points.length; i++)
        if (points[i].seasonId != points[i - 1].seasonId)
          ((fractionOf(i) + fractionOf(i + 1)) / 2, formatRankCode(points[i].seasonId).toUpperCase()),
    ];
    final String linePoints = <String>[
      for (int i = 0; i < values.length; i++) '${_n(fractionOf(i) * _plotUnits)},${_n(yOf(values[i]))}',
    ].join(' ');
    final double endFraction = fractionOf(values.length - 1);
    final double endY = yOf(values.last);

    return div(
      classes: 'rating-chart',
      attributes: <String, String>{'role': 'img', 'aria-label': label},
      <Component>[
        svg(
          classes: 'rating-chart__plot',
          viewBox: '0 0 ${_plotUnits.toInt()} ${_height.toInt()}',
          attributes: const <String, String>{'preserveAspectRatio': 'none', 'aria-hidden': 'true'},
          <Component>[
            for (final int value in gridValues)
              line(
                x1: '0',
                y1: _n(yOf(value)),
                x2: '${_plotUnits.toInt()}',
                y2: _n(yOf(value)),
                stroke: AppColors.divider,
                strokeWidth: '1',
                attributes: const <String, String>{'vector-effect': 'non-scaling-stroke'},
                const <Component>[],
              ),
            for (final (double fraction, String _) in seasons)
              line(
                x1: _n(fraction * _plotUnits),
                y1: '16',
                x2: _n(fraction * _plotUnits),
                y2: _n(gridBottom + 20),
                stroke: AppColors.borderStrong,
                strokeWidth: '1',
                attributes: const <String, String>{
                  'vector-effect': 'non-scaling-stroke',
                  'stroke-dasharray': '3 4',
                },
                const <Component>[],
              ),
            polyline(
              points: linePoints,
              stroke: AppColors.primary,
              strokeWidth: '2.5',
              attributes: const <String, String>{
                'fill': 'none',
                'vector-effect': 'non-scaling-stroke',
                'stroke-linecap': 'round',
                'stroke-linejoin': 'round',
              },
              const <Component>[],
            ),
          ],
        ),
        for (final int value in gridValues)
          span(
            classes: 'rating-chart__grid-label',
            styles: Styles(
              position: Position.absolute(top: Unit.pixels(yOf(value)), right: Unit.zero),
            ),
            <Component>[Component.text('$value')],
          ),
        for (final (double fraction, String name) in seasons)
          span(
            classes: 'rating-chart__season',
            styles: Styles(
              position: Position.absolute(top: const Unit.pixels(14), left: _left(fraction, 6)),
            ),
            <Component>[Component.text(name)],
          ),
        div(
          classes: 'rating-chart__dot',
          styles: Styles(
            position: Position.absolute(top: Unit.pixels(endY), left: _left(endFraction)),
          ),
          const <Component>[],
        ),
        span(
          classes: 'rating-chart__date',
          styles: const Styles(
            position: Position.absolute(top: Unit.pixels(_height - 18), left: Unit.zero),
          ),
          <Component>[Component.text(_day(points.first.finishedAt))],
        ),
        span(
          classes: 'rating-chart__date',
          styles: const Styles(
            position: Position.absolute(top: Unit.pixels(_height - 18), right: Unit.pixels(_labelWidth)),
          ),
          <Component>[Component.text(_day(points.last.finishedAt))],
        ),
      ],
    );
  }
}

@css
List<StyleRule> get ratingHistoryChartStyles => <StyleRule>[
  css('.rating-chart__empty')
      .styles(padding: const Padding.symmetric(vertical: Unit.pixels(24)))
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.muted)),
  css('.rating-chart').styles(
    position: const Position.relative(),
    width: const Unit.percent(100),
    height: const Unit.pixels(230),
  ),
  css('.rating-chart__plot').styles(
    position: const Position.absolute(top: Unit.zero, left: Unit.zero),
    width: const Unit.expression('calc(100% - 40px)'),
    height: const Unit.pixels(230),
    overflow: Overflow.visible,
  ),
  css('.rating-chart__grid-label')
      .styles(
        width: const Unit.pixels(32),
        transform: const Transform.translate(y: Unit.percent(-50)),
      )
      .combine(AppTextStyles.monoCaption)
      .combine(const Styles(color: AppColors.faint, whiteSpace: WhiteSpace.noWrap)),
  css('.rating-chart__season')
      .combine(AppTextStyles.monoCaption)
      .combine(
        const Styles(
          color: AppColors.muted,
          fontSize: Unit.pixels(10),
          lineHeight: Unit.pixels(12),
          whiteSpace: WhiteSpace.noWrap,
        ),
      ),
  css('.rating-chart__dot').styles(
    width: const Unit.pixels(12),
    height: const Unit.pixels(12),
    border: Border.all(color: AppColors.white, width: const Unit.pixels(2)),
    radius: const BorderRadius.circular(Unit.percent(50)),
    transform: const Transform.translate(x: Unit.percent(-50), y: Unit.percent(-50)),
    backgroundColor: AppColors.primary,
  ),
  css('.rating-chart__date')
      .combine(AppTextStyles.bodyXs)
      .combine(
        const Styles(
          color: AppColors.muted,
          fontSize: Unit.pixels(11),
          lineHeight: Unit.pixels(14),
          whiteSpace: WhiteSpace.noWrap,
        ),
      ),
];
