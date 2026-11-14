import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';

/// The spaced mono caption above titles ("STEP 1 — CHOOSE A SUBJECT",
/// "MATH · RANKED"). The text is shown upper case.
final class AppEyebrow extends StatelessWidget {
  const AppEyebrow(
    this.text, {
    this.color = AppColors.muted,
    this.textAlign,
    super.key,
  });

  final String text;
  final Color color;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.eyebrow.copyWith(color: color),
      textAlign: textAlign,
    );
  }
}

/// A small filled circle used as a status marker (online, info notes).
final class AppDot extends StatelessWidget {
  const AppDot({required this.color, this.size = 8, super.key});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
