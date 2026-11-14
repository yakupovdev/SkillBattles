import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';

/// A bordered (or tinted) rounded block.
final class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.color,
    this.borderColor = AppColors.border,
    this.radius = 16,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  /// `null` for a borderless tinted card.
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final Color? border = borderColor;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: border == null ? null : Border.all(color: border),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
