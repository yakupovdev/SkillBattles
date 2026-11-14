import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/features/account/domain/entity/rating_history_point_entity.dart';

/// Pro line chart of the last settled ranked results (no artificial points
/// at season resets: the line simply jumps).
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
        height: 160,
        child: CustomPaint(
          painter: _ChartPainter(points: sorted),
          size: Size.infinite,
        ),
      ),
    );
  }
}

final class _ChartPainter extends CustomPainter {
  const _ChartPainter({required this.points});

  final List<RatingHistoryPointEntity> points;

  @override
  void paint(Canvas canvas, Size size) {
    final List<int> values = <int>[
      points.first.ratingBefore,
      for (final RatingHistoryPointEntity point in points) point.ratingAfter,
    ];
    final int minValue = values.reduce(math.min);
    final int maxValue = values.reduce(math.max);
    final double span = math.max(20, (maxValue - minValue).toDouble());
    const double labelWidth = 44;
    final double width = size.width - labelWidth;
    final double height = size.height - 8;
    Offset at(int index, int value) => Offset(
      labelWidth +
          width * (values.length == 1 ? 0 : index / (values.length - 1)),
      4 + height * (1 - (value - minValue) / span),
    );

    final Paint grid = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1;
    for (final int value in <int>[minValue, maxValue]) {
      final double y = at(0, value).dy;
      canvas.drawLine(Offset(labelWidth, y), Offset(size.width, y), grid);
      final TextPainter label = TextPainter(
        text: TextSpan(
          text: '$value',
          style: AppTextStyles.monoBodySm.copyWith(color: AppColors.muted),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(0, y - label.height / 2));
    }

    final Path line = Path()..moveTo(at(0, values[0]).dx, at(0, values[0]).dy);
    for (int i = 1; i < values.length; i++) {
      final Offset point = at(i, values[i]);
      line.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    final Paint dot = Paint()..color = AppColors.primary;
    for (int i = 1; i < values.length; i++) {
      canvas.drawCircle(at(i, values[i]), 3, dot);
    }
  }

  @override
  bool shouldRepaint(_ChartPainter oldDelegate) => oldDelegate.points != points;
}
