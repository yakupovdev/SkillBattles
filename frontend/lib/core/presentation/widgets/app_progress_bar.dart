import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';

/// A thin rounded progress track.
final class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    required this.fraction,
    this.color = AppColors.primary,
    this.trackColor = AppColors.surface,
    this.height = 6,
    super.key,
  });

  final double fraction;
  final Color color;
  final Color trackColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(height / 2);
    return ClipRRect(
      borderRadius: radius,
      child: ColoredBox(
        color: trackColor,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fraction.clamp(0, 1).toDouble(),
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color, borderRadius: radius),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
