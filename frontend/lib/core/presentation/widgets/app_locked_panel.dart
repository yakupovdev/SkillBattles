import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/pro_badge.dart';

/// A Pro-only block shown to Free readers. It says what is restricted; it
/// never pretends there is no data and never renders hidden values.
final class AppLockedPanel extends StatelessWidget {
  const AppLockedPanel({
    required this.title,
    required this.message,
    required this.onUpgrade,
    this.actionLabel = 'See Pro plans',
    super.key,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          spacing: 16,
          children: <Widget>[
            const ProBadge(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: <Widget>[
                  Text(title, style: AppTextStyles.buttonLg),
                  Text(
                    message,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.muted,
                      height: 18 / 13,
                    ),
                  ),
                ],
              ),
            ),
            AppButton(
              label: actionLabel,
              variant: AppButtonVariant.dark,
              size: AppButtonSize.small,
              onPressed: onUpgrade,
            ),
          ],
        ),
      ),
    );
  }
}
