import 'package:jaspr/dom.dart';

import 'package:skill_battles/app/theme/app_colors.dart';

/// Elevations of the design.
abstract final class AppShadows {
  /// Floating surfaces over page content: notification cards, toasts, pills.
  static const BoxShadow overlay = BoxShadow(
    offsetX: Unit.zero,
    offsetY: Unit.pixels(8),
    blur: Unit.pixels(24),
    color: AppColors.shadow,
  );

  /// The large shadow under dialogs.
  static const BoxShadow dialog = BoxShadow(
    offsetX: Unit.zero,
    offsetY: Unit.pixels(24),
    blur: Unit.pixels(64),
    color: AppColors.dialogShadow,
  );
}
