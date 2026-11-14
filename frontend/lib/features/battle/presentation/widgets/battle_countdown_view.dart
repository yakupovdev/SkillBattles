import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_countdown_text.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_snapshot_entity.dart';

/// COUNTDOWN: a big number only — the round difficulties stay hidden.
final class BattleCountdownView extends StatelessWidget {
  const BattleCountdownView({required this.snapshot, super.key});

  final BattleSnapshotEntity snapshot;

  @override
  Widget build(BuildContext context) {
    final DateTime? endsAt = snapshot.countdownEndsAt;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 96),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: <Widget>[
            const AppEyebrow('Get ready', color: AppColors.primary),
            if (endsAt != null)
              Semantics(
                liveRegion: true,
                child: AppCountdownText(
                  target: endsAt,
                  clockOffset: snapshot.clockOffset,
                  format: AppCountdownFormat.compact,
                  style: AppTextStyles.displayXl.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            Text(
              '${snapshot.questionCount} rounds · same question, same clock',
              style: AppTextStyles.bodyLg.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
