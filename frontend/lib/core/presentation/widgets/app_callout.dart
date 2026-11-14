import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_link.dart';

/// Colors and icon of an [AppCallout].
enum AppCalloutTone {
  /// "Check your inbox".
  success(
    AppColors.successCallout,
    AppColors.successTitle,
    AppColors.successBody,
    AppIcons.statusSuccess,
  ),

  /// "This link has expired or was already used".
  danger(
    AppColors.dangerSurface,
    AppColors.dangerTitle,
    AppColors.dangerBody,
    AppIcons.statusError,
  );

  const AppCalloutTone(this.background, this.title, this.body, this.icon);

  final Color background;
  final Color title;
  final Color body;
  final String icon;
}

/// A tinted result box with a round status icon, a bold title, a body and
/// an optional inline link after the body.
final class AppCallout extends StatelessWidget {
  const AppCallout({
    required this.title,
    required this.message,
    required this.tone,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String message;
  final AppCalloutTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final String? label = actionLabel;
    final TextStyle bodyStyle = AppTextStyles.bodySm.copyWith(
      color: tone.body,
      height: 19 / 13,
    );
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tone.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: <Widget>[
              AppSvgIcon(tone.icon, width: 20, height: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: <Widget>[
                    Text(
                      title,
                      style: AppTextStyles.buttonMd.copyWith(color: tone.title),
                    ),
                    Text(message, style: bodyStyle),
                    if (label != null)
                      AppTextLink(
                        label: label,
                        style: bodyStyle.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        onPressed: onAction,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
