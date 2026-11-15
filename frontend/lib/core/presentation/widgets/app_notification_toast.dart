import 'package:material_ui/material_ui.dart';

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
final class AppNotificationToast extends StatelessWidget {
  const AppNotificationToast({
    required this.kind,
    required this.message,
    super.key,
  });

  final AppNotificationToastKind kind;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.overlay,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            spacing: 12,
            children: <Widget>[
              _ToastIcon(kind: kind),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ToastIcon extends StatelessWidget {
  const _ToastIcon({required this.kind});

  final AppNotificationToastKind kind;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      AppNotificationToastKind.progress => const SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.primary,
          backgroundColor: AppColors.divider,
        ),
      ),
      AppNotificationToastKind.success => const AppSvgIcon(
        AppIcons.statusSuccess,
        width: 20,
        height: 20,
      ),
      AppNotificationToastKind.clock => const AppSvgIcon(
        AppIcons.clock,
        width: 20,
        height: 20,
      ),
      AppNotificationToastKind.info => const AppSvgIcon(
        AppIcons.info,
        width: 20,
        height: 20,
      ),
    };
  }
}
