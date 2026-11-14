import 'package:material_ui/material_ui.dart';

/// Colors of the SkillBattles Paper design. The Paper file has no tokens, so
/// these are the hex values used across all artboards, named by role.
abstract final class AppColors {
  // Brand.
  static const Color primary = Color(0xFF2B4BF2);
  static const Color primarySurface = Color(0xFFF5F7FF);
  static const Color primaryTint = Color(0xFFEEF1FE);
  static const Color primaryRing = Color(0xFFD9DEFB);

  /// Lines, tracks and borders on blue-tinted surfaces.
  static const Color primaryLine = Color(0xFFDCE2FF);

  /// Navy text on blue-tinted surfaces.
  static const Color primaryInk = Color(0xFF2B3570);

  // Text.
  static const Color ink = Color(0xFF0E0F12);
  static const Color inkSoft = Color(0xFF33363D);
  static const Color muted = Color(0xFF6B6F7A);
  static const Color faint = Color(0xFFA0A3AB);

  // Surfaces and lines.
  static const Color white = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF4F5F7);
  static const Color border = Color(0xFFE6E7EB);
  static const Color divider = Color(0xFFEEF0F3);
  static const Color borderStrong = Color(0xFFD2D4DA);

  // Semantic.
  static const Color success = Color(0xFF12A150);
  static const Color successSurface = Color(0xFFE8F7EE);
  static const Color successCallout = Color(0xFFEEF9F2);
  static const Color successTitle = Color(0xFF0B6B35);
  static const Color successBody = Color(0xFF2E5E43);
  static const Color danger = Color(0xFFE5484D);
  static const Color dangerSurface = Color(0xFFFDEEEE);
  static const Color dangerTitle = Color(0xFFA3262B);
  static const Color dangerBody = Color(0xFF7A3A3D);

  /// Red text on a light red surface ("Your answer · Incorrect").
  static const Color dangerText = Color(0xFFC8353A);
  static const Color accent = Color(0xFFF5A524);
  static const Color accentSurface = Color(0xFFFFF8EB);
  static const Color accentText = Color(0xFFB5770A);
  static const Color accentInk = Color(0xFF6A4A0C);

  /// Overtime tag and callout background.
  static const Color accentTint = Color(0xFFFFF4E0);

  /// Body text of the overtime callout.
  static const Color accentCalloutText = Color(0xFF5C3A00);

  /// Overtime row of the round review.
  static const Color accentRowSurface = Color(0xFFFFFAF0);
  static const Color accentRowBorder = Color(0xFFF5D9A3);

  /// Label of the outlined "Go Pro" pill.
  static const Color accentDeep = Color(0xFFB26F00);

  // Text and lines on the primary-colored panel of the auth screen.
  static const Color onPrimaryBody = Color(0xD1FFFFFF);
  static const Color onPrimarySubtle = Color(0xCCFFFFFF);
  static const Color onPrimaryMuted = Color(0xB3FFFFFF);
  static const Color onPrimaryRingOuter = Color(0x2EFFFFFF);
  static const Color onPrimaryRingInner = Color(0x1FFFFFFF);

  // Text and lines on ink panels ("Pro Annual" plan, locked analytics).
  static const Color onDarkMuted = Color(0xB3FFFFFF);
  static const Color onDarkSubtle = Color(0x99FFFFFF);
  static const Color onDarkFaint = Color(0x80FFFFFF);
  static const Color onDarkLine = Color(0x1FFFFFFF);

  static const Color shadow = Color(0x140E0F12);

  /// Dialog backdrop and the large dialog shadow.
  static const Color scrim = Color(0x660E0F12);
  static const Color dialogShadow = Color(0x330E0F12);

  // Skeleton loading.
  static const Color skeletonLight = Color(0xFFEDEEF1);
  static const Color skeletonHighlight = Color(0xFFF7F8FA);

  // Pro badge (amber on ink).
  static const Color pro = Color(0xFFF5A524);
  static const Color proInk = Color(0xFF0E0F12);
}
