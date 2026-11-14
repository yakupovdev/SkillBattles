import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/battle_reason.dart';
import 'package:skill_battles/core/domain/entity/battle_result_entity.dart';
import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';

/// CANCELLED: why the match did not happen, and the way out.
final class BattleCancelledView extends StatelessWidget {
  const BattleCancelledView({required this.result, super.key});

  final BattleResultEntity? result;

  @override
  Widget build(BuildContext context) {
    final BattleReason? reason = result?.reason;
    final bool quota = reason == BattleReason.quotaExhausted;
    final String detail = switch (reason) {
      BattleReason.quotaExhausted =>
        'Your free ranked matches for today ran out before the first '
            'question. Nothing was counted. Private duels stay unlimited.',
      BattleReason.readyTimeout =>
        'Not everyone confirmed in time. No match was played.',
      BattleReason.serverInterruption =>
        'The server restarted. The match was cancelled without a rating '
            'change and a used ranked attempt was returned.',
      BattleReason.bothDisconnected =>
        'Both players lost the connection. The match was cancelled and a '
            'used ranked attempt was returned.',
      BattleReason.surrender => 'The match was left before it started.',
      _ => 'The match was cancelled.',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: <Widget>[
              Text(
                'Match cancelled',
                style: AppTextStyles.displaySm,
                textAlign: TextAlign.center,
              ),
              if (reason != null)
                Text(
                  reason.describe(iWon: false, isDraw: false),
                  style: AppTextStyles.buttonLg,
                ),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLg.copyWith(
                  color: AppColors.muted,
                  height: 22 / 15,
                ),
              ),
              if (result != null)
                Text(
                  DisplayFormatters.dateTime(result!.finishedAt),
                  style: AppTextStyles.bodyXs.copyWith(color: AppColors.faint),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: <Widget>[
                  AppButton(
                    label: 'Back to home',
                    size: AppButtonSize.medium,
                    onPressed: context.goHome,
                  ),
                  if (quota)
                    AppButton(
                      label: 'See Pro plans',
                      variant: AppButtonVariant.outline,
                      size: AppButtonSize.medium,
                      onPressed: context.goPro,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
