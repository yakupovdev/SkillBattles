import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_shadows.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/overlay/app_overlay.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_countdown_text.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/utils/feature_flags.dart';
import 'package:skill_battles/features/account/domain/entity/limits_entity.dart';

/// Opens the "daily ranked limit" modal (Paper: "15 Daily limit reached").
Future<void> showHomeDailyLimitDialog(
  BuildContext context, {
  required LimitsEntity limits,
  required String disciplineCode,
}) {
  return showAppDialog<void>(
    context: context,
    barrierColor: AppColors.scrim,
    builder: (BuildContext dialogContext) => HomeDailyLimitDialog(
      limits: limits,
      onGoPro: () {
        closeAppDialog<void>(dialogContext);
        context.goPro();
      },
      onPrivateDuel: () {
        closeAppDialog<void>(dialogContext);
        context.goPrivateDuel(disciplineCode: disciplineCode);
      },
      onDismiss: () => closeAppDialog<void>(dialogContext),
    ),
  );
}

/// Free ranked matches are used up: when they come back, and the ways on.
final class HomeDailyLimitDialog extends StatelessComponent {
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
  Component build(BuildContext context) {
    return div(classes: 'home-limit-dialog', <Component>[
      div(classes: 'home-limit-dialog__intro', <Component>[
        const AppEyebrow('Daily ranked limit'),
        h2(classes: 'home-limit-dialog__title', <Component>[
          Component.text('That’s all ${limits.freeRankedLimit} ranked matches for today'),
        ]),
        const p(classes: 'home-limit-dialog__body', <Component>[
          Component.text(
            FeatureFlags.billing
                ? 'Your free ranked matches come back at midnight Eastern '
                      'Time. Private duels with friends are always unlimited.'
                : 'Your ranked matches come back at midnight Eastern '
                      'Time. Private duels with friends are always unlimited.',
          ),
        ]),
      ]),
      _ResetBox(resetsAt: limits.resetsAt),
      div(classes: 'home-limit-dialog__actions', <Component>[
        if (FeatureFlags.billing)
          AppButton(
            label: 'Unlimited ranked with Pro',
            variant: AppButtonVariant.dark,
            expand: true,
            icon: const AppSvgIcon(AppIcons.star, width: 14, height: 14),
            onPressed: onGoPro,
          ),
        div(classes: 'home-limit-dialog__row', <Component>[
          AppButton(
            label: 'Create private duel',
            variant: AppButtonVariant.outline,
            size: AppButtonSize.medium,
            expand: true,
            onPressed: onPrivateDuel,
          ),
          button(
            classes: 'home-limit-dialog__dismiss',
            onClick: onDismiss,
            <Component>[const Component.text('Not now')],
          ),
        ]),
      ]),
    ]);
  }
}

final class _ResetBox extends StatelessComponent {
  const _ResetBox({required this.resetsAt});

  final DateTime resetsAt;

  @override
  Component build(BuildContext context) {
    return div(classes: 'home-reset-box', <Component>[
      div(classes: 'home-reset-box__countdown', <Component>[
        const p(classes: 'home-reset-box__label', <Component>[Component.text('Resets in')]),
        AppCountdownText(
          target: resetsAt,
          format: AppCountdownFormat.hms,
          style: AppTextStyles.monoSm.combine(
            const Styles(display: Display.block, fontSize: Unit.pixels(24), lineHeight: Unit.pixels(30)),
          ),
        ),
      ]),
      p(classes: 'home-reset-box__local', <Component>[
        Component.text(
          '${DisplayFormatters.weekdayDate(resetsAt)}\n'
          '${DisplayFormatters.time(resetsAt)} your time',
        ),
      ]),
    ]);
  }
}

@css
List<StyleRule> get homeDailyLimitDialogStyles => <StyleRule>[
  css('.home-limit-dialog').styles(
    display: Display.flex,
    width: const Unit.pixels(480),
    maxWidth: const Unit.percent(100),
    padding: const Padding.all(Unit.pixels(36)),
    radius: const BorderRadius.circular(Unit.pixels(20)),
    shadow: AppShadows.dialog,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(24)),
    backgroundColor: AppColors.white,
  ),
  css('.home-limit-dialog__intro').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(10)),
  ),
  css('.home-limit-dialog__title')
      .combine(AppTextStyles.titleXl)
      .combine(const Styles(letterSpacing: Unit.em(-0.025), lineHeight: Unit.pixels(36))),
  css('.home-limit-dialog__body')
      .combine(AppTextStyles.bodyLg)
      .combine(const Styles(color: AppColors.muted, lineHeight: Unit.pixels(22))),
  css('.home-limit-dialog__actions').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(10)),
  ),
  css('.home-limit-dialog__row').styles(display: Display.flex, gap: const Gap.column(Unit.pixels(10))),
  css('.home-limit-dialog__row > *').styles(
    minWidth: Unit.zero,
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.home-limit-dialog__dismiss')
      .styles(
        height: const Unit.pixels(48),
        radius: const BorderRadius.circular(Unit.pixels(12)),
        cursor: Cursor.pointer,
        backgroundColor: Colors.transparent,
      )
      .combine(AppTextStyles.bodyMd)
      .combine(const Styles(color: AppColors.muted, fontWeight: FontWeight.w500)),
  css('.home-limit-dialog__dismiss:hover').styles(backgroundColor: AppColors.surface),
  css('.home-reset-box').styles(
    display: Display.flex,
    padding: const Padding.symmetric(horizontal: Unit.pixels(18), vertical: Unit.pixels(16)),
    radius: const BorderRadius.circular(Unit.pixels(12)),
    alignItems: AlignItems.center,
    backgroundColor: AppColors.surface,
  ),
  css('.home-reset-box__countdown').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(2)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.home-reset-box__label').combine(AppTextStyles.bodyXs).combine(const Styles(color: AppColors.muted)),
  css('.home-reset-box__local')
      .styles(whiteSpace: WhiteSpace.preLine)
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.muted, textAlign: TextAlign.right, lineHeight: Unit.pixels(18))),
];
