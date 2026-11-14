import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';

/// Colors of a [ProBadge].
enum ProBadgeTone {
  /// Amber text on ink (lists, headers).
  ink(AppColors.proInk, AppColors.pro),

  /// Ink text on amber (account settings).
  amber(AppColors.pro, AppColors.proInk);

  const ProBadgeTone(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

/// The public PRO badge. It is only a badge: Pro never changes Elo,
/// matchmaking or scoring.
final class ProBadge extends StatelessWidget {
  const ProBadge({
    this.compact = false,
    this.tone = ProBadgeTone.ink,
    super.key,
  });

  final bool compact;
  final ProBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pro member',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tone.background,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 4 : 6,
            vertical: compact ? 1 : 2,
          ),
          child: Text(
            'PRO',
            style: AppTextStyles.outcome.copyWith(
              fontSize: compact ? 9 : 10,
              height: compact ? 12 / 9 : 14 / 10,
              letterSpacing: 0.06 * 10,
              color: tone.foreground,
              fontWeight: tone == ProBadgeTone.amber ? FontWeight.w700 : null,
            ),
          ),
        ),
      ),
    );
  }
}
