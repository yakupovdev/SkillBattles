import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';

/// The amber-on-ink "TEST MODE" chip: Stripe runs with test cards only.
final class AppTestModeBadge extends StatelessWidget {
  const AppTestModeBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          'TEST MODE',
          style: AppTextStyles.monoCaption.copyWith(
            fontSize: 10,
            height: 12 / 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.06 * 10,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }
}
