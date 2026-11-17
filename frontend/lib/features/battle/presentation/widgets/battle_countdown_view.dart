import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_countdown_text.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_snapshot_entity.dart';

/// COUNTDOWN: a big number only — the round difficulties stay hidden.
final class BattleCountdownView extends StatelessComponent {
  const BattleCountdownView({required this.snapshot, super.key});

  final BattleSnapshotEntity snapshot;

  @override
  Component build(BuildContext context) {
    final DateTime? endsAt = snapshot.countdownEndsAt;
    return div(classes: 'battle-countdown', <Component>[
      const AppEyebrow('Get ready', color: AppColors.primary),
      if (endsAt != null)
        div(
          attributes: const <String, String>{'aria-live': 'polite'},
          <Component>[
            AppCountdownText(
              target: endsAt,
              clockOffset: snapshot.clockOffset,
              format: AppCountdownFormat.seconds,
              style: AppTextStyles.displayXl.combine(const Styles(color: AppColors.primary)),
            ),
          ],
        ),
      p(classes: 'battle-countdown__note', <Component>[
        Component.text('${snapshot.questionCount} rounds · same question, same clock'),
      ]),
    ]);
  }
}

@css
List<StyleRule> get battleCountdownViewStyles => <StyleRule>[
  css('.battle-countdown').styles(
    display: Display.flex,
    padding: const Padding.symmetric(vertical: Unit.pixels(96)),
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.center,
    gap: const Gap.row(Unit.pixels(16)),
  ),
  css('.battle-countdown__note').combine(AppTextStyles.bodyLg).combine(const Styles(color: AppColors.muted)),
];
