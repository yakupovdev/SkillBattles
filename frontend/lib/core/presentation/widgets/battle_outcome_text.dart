import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/battle_outcome.dart';
import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';

/// "WIN" / "LOSS" / "DRAW" in mono, green / red / grey.
final class BattleOutcomeText extends StatelessWidget {
  const BattleOutcomeText({required this.outcome, super.key});

  final BattleOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (outcome) {
      BattleOutcome.win => AppColors.success,
      BattleOutcome.loss => AppColors.danger,
      BattleOutcome.draw || BattleOutcome.cancelled => AppColors.muted,
    };
    return Text(
      outcome.label,
      style: AppTextStyles.outcome.copyWith(color: color),
    );
  }
}

/// A rating change in mono: "+16" green, "−14" red (true minus sign), and a
/// grey "—" when there is no change (`null` or 0, e.g. a private duel).
final class RatingDeltaText extends StatelessWidget {
  const RatingDeltaText({
    required this.delta,
    this.style = AppTextStyles.monoBodyMd,
    this.textAlign = TextAlign.right,
    super.key,
  });

  final int? delta;
  final TextStyle style;
  final TextAlign textAlign;

  /// Formats a rating change the way the design writes it.
  static String format(int? delta) {
    final int? value = delta;
    if (value == null || value == 0) return '—';
    return value > 0 ? '+$value' : '−${value.abs()}';
  }

  @override
  Widget build(BuildContext context) {
    final int? value = delta;
    final Color color = value == null || value == 0
        ? AppColors.faint
        : value > 0
        ? AppColors.success
        : AppColors.danger;
    return Text(
      format(value),
      style: style.copyWith(color: color),
      textAlign: textAlign,
    );
  }
}
