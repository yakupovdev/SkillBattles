import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';

/// "Reconnecting…" pill shown while the realtime connection is down.
final class AppConnectionIndicator extends StatelessWidget {
  const AppConnectionIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: const ShapeDecoration(
          color: AppColors.surface,
          shape: StadiumBorder(),
        ),
        child: SizedBox(
          height: 32,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: <Widget>[
                const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.muted,
                    backgroundColor: AppColors.border,
                  ),
                ),
                Text(
                  'Reconnecting…',
                  style: AppTextStyles.bodySm.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
