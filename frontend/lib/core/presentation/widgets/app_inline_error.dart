import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';

/// A form-level error under the fields, announced to screen readers.
final class AppInlineError extends StatelessWidget {
  const AppInlineError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: AppTextStyles.bodySm.copyWith(
          color: AppColors.danger,
          height: 18 / 13,
        ),
      ),
    );
  }
}
