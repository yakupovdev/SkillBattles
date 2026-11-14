import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';

/// Centered failure message with a retry button.
final class AppErrorView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return _StatusLayout(
      title: title,
      message: message,
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
final class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return _StatusLayout(title: title, message: message, action: action);
  }
}

final class _StatusLayout extends StatelessWidget {
  const _StatusLayout({
    required this.title,
    required this.message,
    this.action,
  });

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final Widget? button = action;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: <Widget>[
              Text(
                title,
                style: AppTextStyles.titleMd,
                textAlign: TextAlign.center,
              ),
              Text(
                message,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              if (button != null)
                Padding(padding: const EdgeInsets.only(top: 8), child: button),
            ],
          ),
        ),
      ),
    );
  }
}
