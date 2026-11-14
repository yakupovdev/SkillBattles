import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';
import 'package:skill_battles/features/account/domain/entity/rating_history_point_entity.dart';

/// Pro line chart of the last settled ranked results (Paper: "21 Stats
/// (Pro)"). Season resets get no artificial points: the line simply jumps
/// across a dashed season divider.
final class RatingHistoryChart extends StatelessWidget {
  const RatingHistoryChart({required this.points, super.key});

  /// Newest first or oldest first; drawn by `finishedAt`.
  final List<RatingHistoryPointEntity> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'Play ranked matches to draw your rating graph.',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
        ),
      );
    }
    final List<RatingHistoryPointEntity> sorted =
        <RatingHistoryPointEntity>[...points]..sort(
          (RatingHistoryPointEntity a, RatingHistoryPointEntity b) =>
              a.finishedAt.compareTo(b.finishedAt),
        );
    final int first = sorted.first.ratingBefore;
    final int last = sorted.last.ratingAfter;
    return Semantics(
      label:
          'Rating graph of the last ${sorted.length} ranked matches, from '
          '$first to $last',
      excludeSemantics: true,
      child: SizedBox(
        height: 230,
        child: CustomPaint(
          painter: _ChartPainter(points: sorted, now: DateTime.now()),
          size: Size.infinite,
        ),
      ),
    );
  }
}

final class _ChartPainter extends CustomPainter {
  const _ChartPainter({required this.points, required this.now});

  final List<RatingHistoryPointEntity> points;
  final DateTime now;

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

  /// Space for the grid labels on the right.
  static const double _labelWidth = 40;
  static const double _gridTop = 40;

  /// The grid ends 50 px above the bottom; the date labels sit below it.
  static const double _gridBottomInset = 50;

  String _day(DateTime value) {
    final DateTime local = value.toLocal();
    final DateTime today = now.toLocal();
    if (local.year == today.year &&
        local.month == today.month &&
        local.day == today.day) {
      return 'Today';
    }
    return '${_months[local.month - 1]} ${local.day}';
  }

  TextPainter _text(String text, TextStyle style) => TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
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

    final double chartWidth = size.width - _labelWidth;
    final double gridBottom = size.height - _gridBottomInset;
    double yOf(num value) =>
        gridBottom - (value - low) / (high - low) * (gridBottom - _gridTop);
    double xOf(int index) =>
        values.length == 1 ? 0 : chartWidth * index / (values.length - 1);

    final TextStyle gridLabel = AppTextStyles.monoCaption.copyWith(
      color: AppColors.faint,
    );
    final Paint grid = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1;
    for (int value = low; value <= high; value += step) {
      final double y = yOf(value);
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), grid);
      final TextPainter label = _text('$value', gridLabel);
      label.paint(canvas, Offset(chartWidth + 8, y - label.height / 2));
    }

    // Season dividers between the last match of a season and the first of
    // the next one.
    final Paint dash = Paint()
      ..color = AppColors.borderStrong
      ..strokeWidth = 1;
    for (int i = 1; i < points.length; i++) {
      if (points[i].seasonId == points[i - 1].seasonId) continue;
      final double x = (xOf(i) + xOf(i + 1)) / 2;
      for (double y = 16; y < gridBottom + 20; y += 7) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 3), dash);
      }
      _text(
        formatRankCode(points[i].seasonId).toUpperCase(),
        AppTextStyles.monoCaption.copyWith(
          fontSize: 10,
          height: 12 / 10,
          color: AppColors.muted,
        ),
      ).paint(canvas, Offset(x + 6, 14));
    }

    final Path line = Path()..moveTo(xOf(0), yOf(values[0]));
    for (int i = 1; i < values.length; i++) {
      line.lineTo(xOf(i), yOf(values[i]));
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final Offset end = Offset(xOf(values.length - 1), yOf(values.last));
    canvas
      ..drawCircle(end, 6, Paint()..color = AppColors.white)
      ..drawCircle(end, 4, Paint()..color = AppColors.primary);

    final TextStyle dateStyle = AppTextStyles.bodyXs.copyWith(
      fontSize: 11,
      height: 14 / 11,
      color: AppColors.muted,
    );
    final double dateY = size.height - 18;
    _text(
      _day(points.first.finishedAt),
      dateStyle,
    ).paint(canvas, Offset(0, dateY));
    final TextPainter lastLabel = _text(
      _day(points.last.finishedAt),
      dateStyle,
    );
    lastLabel.paint(canvas, Offset(chartWidth - lastLabel.width, dateY));
  }

  @override
  bool shouldRepaint(_ChartPainter oldDelegate) => oldDelegate.points != points;
}
