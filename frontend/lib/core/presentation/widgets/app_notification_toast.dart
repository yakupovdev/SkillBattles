import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_shadows.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';

/// Leading icon of an [AppNotificationToast].
enum AppNotificationToastKind {
  /// Primary spinner: something is in progress.
  progress,

  /// Green check.
  success,

  /// Muted clock.
  clock,

  /// Muted info mark.
  info,
}

/// A transient, non-actionable message floating over the page. The owner
/// hides it after a few seconds. Announced to screen readers.
final class AppNotificationToast extends StatelessComponent {
  const AppNotificationToast({
    required this.kind,
    required this.message,
    super.key,
  });

  final AppNotificationToastKind kind;
  final String message;

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'app-notification-toast',
      attributes: const <String, String>{'role': 'status', 'aria-live': 'polite'},
      <Component>[
        _ToastIcon(kind: kind),
        p(classes: 'app-notification-toast__message', <Component>[Component.text(message)]),
      ],
    );
  }
}

final class _ToastIcon extends StatelessComponent {
  const _ToastIcon({required this.kind});

  final AppNotificationToastKind kind;

  @override
  Component build(BuildContext context) {
    return switch (kind) {
      AppNotificationToastKind.progress => const span(
        classes: 'app-notification-toast__spinner',
        attributes: <String, String>{'aria-hidden': 'true'},
        <Component>[],
      ),
      AppNotificationToastKind.success => const AppSvgIcon(AppIcons.statusSuccess, width: 20, height: 20),
      AppNotificationToastKind.clock => const AppSvgIcon(AppIcons.clock, width: 20, height: 20),
      AppNotificationToastKind.info => const AppSvgIcon(AppIcons.info, width: 20, height: 20),
    };
  }
}

@css
List<StyleRule> get appNotificationToastStyles => <StyleRule>[
  css('.app-notification-toast').styles(
    display: Display.flex,
    padding: const Padding.symmetric(horizontal: Unit.pixels(16), vertical: Unit.pixels(14)),
    border: Border.all(color: AppColors.border, width: const Unit.pixels(1)),
    radius: const BorderRadius.circular(Unit.pixels(14)),
    shadow: AppShadows.overlay,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(12)),
    backgroundColor: AppColors.white,
  ),
  css('.app-notification-toast__message')
      .styles(
        minWidth: Unit.zero,
        flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
      )
      .combine(AppTextStyles.bodyMd)
      .combine(const Styles(fontWeight: FontWeight.w500)),
  css('.app-notification-toast__spinner').styles(
    display: Display.inlineBlock,
    width: const Unit.pixels(20),
    height: const Unit.pixels(20),
    border: Border.all(color: AppColors.divider, width: const Unit.pixels(2.5)),
    radius: const BorderRadius.circular(Unit.percent(50)),
    flex: const Flex(shrink: 0),
    raw: const <String, String>{
      'border-top-color': '#2B4BF2',
      'animation': 'app-spin 0.8s linear infinite',
    },
  ),
];
