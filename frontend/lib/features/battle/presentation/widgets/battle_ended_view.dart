import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/battle_reason.dart';
import 'package:skill_battles/core/domain/entity/battle_result_entity.dart';
import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/utils/feature_flags.dart';

/// CANCELLED: why the match did not happen, and the way out.
final class BattleCancelledView extends StatelessComponent {
  const BattleCancelledView({required this.result, super.key});

  final BattleResultEntity? result;

  @override
  Component build(BuildContext context) {
    final BattleResultEntity? result = this.result;
    final BattleReason? reason = result?.reason;
    final bool quota = reason == BattleReason.quotaExhausted;
    final String detail = switch (reason) {
      BattleReason.quotaExhausted =>
        FeatureFlags.billing
            ? 'Your free ranked matches for today ran out before the first '
                  'question. Nothing was counted. Private duels stay unlimited.'
            : 'Your ranked matches for today ran out before the first '
                  'question. Nothing was counted. Private duels stay unlimited.',
      BattleReason.readyTimeout => 'Not everyone confirmed in time. No match was played.',
      BattleReason.serverInterruption =>
        'The server restarted. The match was cancelled without a rating '
            'change and a used ranked attempt was returned.',
      BattleReason.bothDisconnected =>
        'Both players lost the connection. The match was cancelled and a '
            'used ranked attempt was returned.',
      BattleReason.surrender => 'The match was left before it started.',
      _ => 'The match was cancelled.',
    };
    return div(classes: 'battle-cancelled', <Component>[
      div(classes: 'battle-cancelled__content', <Component>[
        const h1(classes: 'battle-cancelled__title', <Component>[Component.text('Match cancelled')]),
        if (reason != null)
          p(classes: 'battle-cancelled__reason', <Component>[
            Component.text(reason.describe(iWon: false, isDraw: false)),
          ]),
        p(classes: 'battle-cancelled__detail', <Component>[Component.text(detail)]),
        if (result != null)
          p(classes: 'battle-cancelled__date', <Component>[
            Component.text(DisplayFormatters.dateTime(result.finishedAt)),
          ]),
        div(classes: 'battle-cancelled__actions', <Component>[
          AppButton(label: 'Back to home', size: AppButtonSize.medium, onPressed: context.goHome),
          if (quota && FeatureFlags.billing)
            AppButton(
              label: 'See Pro plans',
              variant: AppButtonVariant.outline,
              size: AppButtonSize.medium,
              onPressed: context.goPro,
            ),
        ]),
      ]),
    ]);
  }
}

@css
List<StyleRule> get battleEndedViewStyles => <StyleRule>[
  css('.battle-cancelled').styles(
    display: Display.flex,
    padding: const Padding.symmetric(horizontal: Unit.pixels(32), vertical: Unit.pixels(96)),
    justifyContent: JustifyContent.center,
  ),
  css('.battle-cancelled__content').styles(
    display: Display.flex,
    width: const Unit.percent(100),
    maxWidth: const Unit.pixels(520),
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.center,
    gap: const Gap.row(Unit.pixels(16)),
  ),
  css('.battle-cancelled__title').combine(AppTextStyles.displaySm).combine(const Styles(textAlign: TextAlign.center)),
  css('.battle-cancelled__reason').combine(AppTextStyles.buttonLg),
  css('.battle-cancelled__detail')
      .combine(AppTextStyles.bodyLg)
      .combine(const Styles(color: AppColors.muted, textAlign: TextAlign.center, lineHeight: Unit.pixels(22))),
  css('.battle-cancelled__date').combine(AppTextStyles.bodyXs).combine(const Styles(color: AppColors.faint)),
  // 8 px more than the column gap (Flutter: SizedBox(height: 8)).
  css('.battle-cancelled__actions').styles(
    display: Display.flex,
    margin: const Margin.only(top: Unit.pixels(24)),
    flexWrap: FlexWrap.wrap,
    justifyContent: JustifyContent.center,
    gap: const Gap.all(Unit.pixels(12)),
  ),
];
