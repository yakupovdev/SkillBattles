import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';

/// Elevations of the design.
abstract final class AppShadows {
  /// Floating surfaces over page content: notification cards, toasts, pills.
  static const List<BoxShadow> overlay = <BoxShadow>[
    BoxShadow(color: AppColors.shadow, offset: Offset(0, 8), blurRadius: 24),
  ];
}
