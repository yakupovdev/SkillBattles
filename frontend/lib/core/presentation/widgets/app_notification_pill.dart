import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_shadows.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';

/// A small outlined pill with a dot that reopens something the player hid.
final class AppNotificationPill extends StatelessComponent {
  const AppNotificationPill({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Component build(BuildContext context) {
    return button(
      type: ButtonType.button,
      classes: 'app-notification-pill',
      onClick: onPressed,
      <Component>[
        const AppDot(color: AppColors.primary),
        span(classes: 'app-notification-pill__label', <Component>[Component.text(label)]),
      ],
    );
  }
}

@css
List<StyleRule> get appNotificationPillStyles => <StyleRule>[
  css('.app-notification-pill').styles(
    display: Display.inlineFlex,
    height: const Unit.pixels(34),
    padding: const Padding.symmetric(horizontal: Unit.pixels(14)),
    border: Border.all(color: AppColors.primary, width: const Unit.pixels(1.5)),
    radius: const BorderRadius.circular(Unit.pixels(999)),
    shadow: AppShadows.overlay,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(8)),
    backgroundColor: AppColors.white,
  ),
  css('.app-notification-pill:hover, .app-notification-pill:focus-visible').styles(
    backgroundColor: AppColors.primarySurface,
  ),
  css('.app-notification-pill__label')
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.primary, fontWeight: FontWeight.w600, whiteSpace: WhiteSpace.noWrap)),
];
