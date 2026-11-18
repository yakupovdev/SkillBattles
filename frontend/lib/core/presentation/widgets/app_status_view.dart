import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';

/// Centered failure message with a retry button.
final class AppErrorView extends StatelessComponent {
  const AppErrorView({
    required this.message,
    this.onRetry,
    this.title = "Couldn't load this page",
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Component build(BuildContext context) {
    return _StatusLayout(
      title: title,
      message: message,
      isAlert: true,
      action: onRetry == null
          ? null
          : AppButton(
              label: 'Try again',
              variant: AppButtonVariant.outline,
              size: AppButtonSize.medium,
              onPressed: onRetry,
            ),
    );
  }
}

/// Centered empty state (a successful answer with nothing in it).
final class AppEmptyView extends StatelessComponent {
  const AppEmptyView({
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final String title;
  final String message;
  final Component? action;

  @override
  Component build(BuildContext context) {
    return _StatusLayout(title: title, message: message, action: action);
  }
}

final class _StatusLayout extends StatelessComponent {
  const _StatusLayout({
    required this.title,
    required this.message,
    this.action,
    this.isAlert = false,
  });

  final String title;
  final String message;
  final Component? action;
  final bool isAlert;

  @override
  Component build(BuildContext context) {
    final Component? button = action;
    return div(classes: 'app-status-view', <Component>[
      div(
        classes: 'app-status-view__content',
        attributes: isAlert ? const <String, String>{'role': 'alert'} : null,
        <Component>[
          h2(classes: 'app-status-view__title', <Component>[Component.text(title)]),
          p(classes: 'app-status-view__message', <Component>[Component.text(message)]),
          if (button != null) div(classes: 'app-status-view__action', <Component>[button]),
        ],
      ),
    ]);
  }
}

@css
List<StyleRule> get appStatusViewStyles => <StyleRule>[
  css('.app-status-view').styles(
    display: Display.flex,
    padding: const Padding.symmetric(horizontal: Unit.pixels(24), vertical: Unit.pixels(48)),
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.center,
    flex: const Flex(grow: 1),
  ),
  css('.app-status-view__content').styles(
    display: Display.flex,
    maxWidth: const Unit.pixels(440),
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.center,
    gap: const Gap.row(Unit.pixels(12)),
    textAlign: TextAlign.center,
  ),
  css('.app-status-view__title').combine(AppTextStyles.titleMd),
  css('.app-status-view__message').combine(AppTextStyles.bodyMd).combine(const Styles(color: AppColors.muted)),
  css('.app-status-view__action').styles(padding: const Padding.only(top: Unit.pixels(8))),
];
