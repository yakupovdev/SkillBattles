import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_shadows.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';

/// A small outlined pill with a dot that reopens something the player hid.
final class AppNotificationPill extends StatelessWidget {
  const AppNotificationPill({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const StadiumBorder shape = StadiumBorder(
      side: BorderSide(color: AppColors.primary, width: 1.5),
    );
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: const ShapeDecoration(
          shape: StadiumBorder(),
          shadows: AppShadows.overlay,
        ),
        child: Material(
          color: AppColors.white,
          shape: shape,
          child: InkWell(
            onTap: onPressed,
            customBorder: shape,
            hoverColor: AppColors.primarySurface,
            focusColor: AppColors.primarySurface,
            child: SizedBox(
              height: 34,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: <Widget>[
                    const AppDot(color: AppColors.primary),
                    Text(
                      label,
                      style: AppTextStyles.bodySm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
