import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_countdown_text.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/features/account/domain/entity/limits_entity.dart';

/// Opens the "daily ranked limit" modal (Paper: "15 Daily limit reached").
Future<void> showHomeDailyLimitDialog(
  BuildContext context, {
  required LimitsEntity limits,
  required String disciplineCode,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.scrim,
    builder: (BuildContext dialogContext) => HomeDailyLimitDialog(
      limits: limits,
      onGoPro: () {
        Navigator.of(dialogContext).pop();
        context.goPro();
      },
      onPrivateDuel: () {
        Navigator.of(dialogContext).pop();
        context.goPrivateDuel(disciplineCode: disciplineCode);
      },
      onDismiss: () => Navigator.of(dialogContext).pop(),
    ),
  );
}

/// Free ranked matches are used up: when they come back, and the ways on.
final class HomeDailyLimitDialog extends StatelessWidget {
  const HomeDailyLimitDialog({
    required this.limits,
    required this.onGoPro,
    required this.onPrivateDuel,
    required this.onDismiss,
    super.key,
  });

  final LimitsEntity limits;
  final VoidCallback onGoPro;
  final VoidCallback onPrivateDuel;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: AppColors.dialogShadow,
              offset: Offset(0, 24),
              blurRadius: 64,
            ),
          ],
        ),
        child: SizedBox(
          width: 480,
          child: Padding(
            padding: const EdgeInsets.all(36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 24,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: <Widget>[
                    const AppEyebrow('Daily ranked limit'),
                    Text(
                      'That’s all ${limits.freeRankedLimit} ranked matches '
                      'for today',
                      style: AppTextStyles.titleXl.copyWith(
                        height: 36 / 32,
                        letterSpacing: -0.025 * 32,
                      ),
                    ),
                    Text(
                      'Your free ranked matches come back at midnight Eastern '
                      'Time. Private duels with friends are always unlimited.',
                      style: AppTextStyles.bodyLg.copyWith(
                        height: 22 / 15,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                _ResetBox(resetsAt: limits.resetsAt),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 10,
                  children: <Widget>[
                    AppButton(
                      label: 'Unlimited ranked with Pro',
                      variant: AppButtonVariant.dark,
                      expand: true,
                      icon: const AppSvgIcon(
                        AppIcons.star,
                        width: 14,
                        height: 14,
                      ),
                      onPressed: onGoPro,
                    ),
                    Row(
                      spacing: 10,
                      children: <Widget>[
                        Expanded(
                          child: AppButton(
                            label: 'Create private duel',
                            variant: AppButtonVariant.outline,
                            size: AppButtonSize.medium,
                            expand: true,
                            onPressed: onPrivateDuel,
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: onDismiss,
                            style: TextButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              foregroundColor: AppColors.muted,
                              textStyle: AppTextStyles.bodyMd.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Not now'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _ResetBox extends StatelessWidget {
  const _ResetBox({required this.resetsAt});

  final DateTime resetsAt;

  @override
  Widget build(BuildContext context) {
    final TextStyle muted = AppTextStyles.bodySm.copyWith(
      color: AppColors.muted,
      height: 18 / 13,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: <Widget>[
                  Text(
                    'Resets in',
                    style: AppTextStyles.bodyXs.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  AppCountdownText(
                    target: resetsAt,
                    format: AppCountdownFormat.hms,
                    style: AppTextStyles.monoSm.copyWith(
                      fontSize: 24,
                      height: 30 / 24,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${DisplayFormatters.weekdayDate(resetsAt)}\n'
              '${DisplayFormatters.time(resetsAt)} your time',
              textAlign: TextAlign.right,
              style: muted,
            ),
          ],
        ),
      ),
    );
  }
}
