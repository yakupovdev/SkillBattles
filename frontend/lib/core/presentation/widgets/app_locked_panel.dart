import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/pro_badge.dart';

/// A Pro-only block shown to Free readers. It says what is restricted; it
/// never pretends there is no data and never renders hidden values.
final class AppLockedPanel extends StatelessComponent {
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
  Component build(BuildContext context) {
    return div(classes: 'app-locked-panel', <Component>[
      const ProBadge(),
      div(classes: 'app-locked-panel__text', <Component>[
        p(classes: 'app-locked-panel__title', <Component>[Component.text(title)]),
        p(classes: 'app-locked-panel__message', <Component>[Component.text(message)]),
      ]),
      AppButton(
        label: actionLabel,
        variant: AppButtonVariant.dark,
        size: AppButtonSize.small,
        onPressed: onUpgrade,
      ),
    ]);
  }
}

@css
List<StyleRule> get appLockedPanelStyles => <StyleRule>[
  css('.app-locked-panel').styles(
    display: Display.flex,
    padding: const Padding.all(Unit.pixels(20)),
    radius: const BorderRadius.circular(Unit.pixels(14)),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(16)),
    backgroundColor: AppColors.surface,
  ),
  css('.app-locked-panel__text').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(4)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.app-locked-panel__title').combine(AppTextStyles.buttonLg),
  css('.app-locked-panel__message')
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.muted, lineHeight: Unit.pixels(18))),
];
