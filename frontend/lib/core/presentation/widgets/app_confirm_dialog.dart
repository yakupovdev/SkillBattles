import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_shadows.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/overlay/app_overlay.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';

/// Asks for confirmation; `true` when confirmed.
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
}) async {
  final bool? confirmed = await showAppDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => AppConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: isDestructive,
    ),
  );
  return confirmed ?? false;
}

final class AppConfirmDialog extends StatelessComponent {
  const AppConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDestructive,
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  @override
  Component build(BuildContext context) {
    return div(classes: 'app-confirm-dialog', <Component>[
      h2(classes: 'app-confirm-dialog__title', <Component>[Component.text(title)]),
      p(classes: 'app-confirm-dialog__message', <Component>[Component.text(message)]),
      div(classes: 'app-confirm-dialog__actions', <Component>[
        AppButton(
          label: cancelLabel,
          variant: AppButtonVariant.outline,
          size: AppButtonSize.small,
          onPressed: () => closeAppDialog<bool>(context, false),
        ),
        AppButton(
          label: confirmLabel,
          variant: isDestructive ? AppButtonVariant.dark : AppButtonVariant.primary,
          size: AppButtonSize.small,
          onPressed: () => closeAppDialog<bool>(context, true),
        ),
      ]),
    ]);
  }
}

@css
List<StyleRule> get appConfirmDialogStyles => <StyleRule>[
  css('.app-confirm-dialog').styles(
    display: Display.flex,
    width: const Unit.pixels(420),
    maxWidth: const Unit.percent(100),
    padding: const Padding.all(Unit.pixels(28)),
    radius: const BorderRadius.circular(Unit.pixels(16)),
    shadow: AppShadows.dialog,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(12)),
    backgroundColor: AppColors.white,
  ),
  css('.app-confirm-dialog__title').combine(AppTextStyles.titleLg),
  css('.app-confirm-dialog__message')
      .combine(AppTextStyles.bodyMd)
      .combine(const Styles(color: AppColors.muted, lineHeight: Unit.pixels(20))),
  css('.app-confirm-dialog__actions').styles(
    display: Display.flex,
    margin: const Margin.only(top: Unit.pixels(8)),
    justifyContent: JustifyContent.end,
    gap: const Gap.column(Unit.pixels(12)),
  ),
];
