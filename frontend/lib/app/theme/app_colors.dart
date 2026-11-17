import 'package:jaspr/dom.dart';

/// Colors of the SkillBattles Paper design. The Paper file has no tokens, so
/// these are the hex values used across all artboards, named by role.
abstract final class AppColors {
  // Brand.
  static const Color primary = Color('#2B4BF2');
  static const Color primarySurface = Color('#F5F7FF');
  static const Color primaryTint = Color('#EEF1FE');
  static const Color primaryRing = Color('#D9DEFB');

  /// Lines, tracks and borders on blue-tinted surfaces.
  static const Color primaryLine = Color('#DCE2FF');

  /// Navy text on blue-tinted surfaces.
  static const Color primaryInk = Color('#2B3570');

  // Text.
  static const Color ink = Color('#0E0F12');
  static const Color inkSoft = Color('#33363D');
  static const Color muted = Color('#6B6F7A');
  static const Color faint = Color('#A0A3AB');

  // Surfaces and lines.
  static const Color white = Color('#FFFFFF');
  static const Color surface = Color('#F4F5F7');
  static const Color border = Color('#E6E7EB');
  static const Color divider = Color('#EEF0F3');
  static const Color borderStrong = Color('#D2D4DA');

  // Semantic.
  static const Color success = Color('#12A150');
  static const Color successSurface = Color('#E8F7EE');
  static const Color successCallout = Color('#EEF9F2');
  static const Color successTitle = Color('#0B6B35');
  static const Color successBody = Color('#2E5E43');
  static const Color danger = Color('#E5484D');
  static const Color dangerSurface = Color('#FDEEEE');
  static const Color dangerTitle = Color('#A3262B');
  static const Color dangerBody = Color('#7A3A3D');

  /// Red text on a light red surface ("Your answer · Incorrect").
  static const Color dangerText = Color('#C8353A');
  static const Color accent = Color('#F5A524');
  static const Color accentSurface = Color('#FFF8EB');
  static const Color accentText = Color('#B5770A');
  static const Color accentInk = Color('#6A4A0C');

  /// Overtime tag and callout background.
  static const Color accentTint = Color('#FFF4E0');

  /// Body text of the overtime callout.
  static const Color accentCalloutText = Color('#5C3A00');

  /// Overtime row of the round review.
  static const Color accentRowSurface = Color('#FFFAF0');
  static const Color accentRowBorder = Color('#F5D9A3');

  /// Label of the outlined "Go Pro" pill.
  static const Color accentDeep = Color('#B26F00');

  // Text and lines on the primary-colored panel of the auth screen.
  static const Color onPrimaryBody = Color('#FFFFFFD1');
  static const Color onPrimarySubtle = Color('#FFFFFFCC');
  static const Color onPrimaryMuted = Color('#FFFFFFB3');
  static const Color onPrimaryRingOuter = Color('#FFFFFF2E');
  static const Color onPrimaryRingInner = Color('#FFFFFF1F');

  // Text and lines on ink panels ("Pro Annual" plan, locked analytics).
  static const Color onDarkMuted = Color('#FFFFFFB3');
  static const Color onDarkSubtle = Color('#FFFFFF99');
  static const Color onDarkFaint = Color('#FFFFFF80');
  static const Color onDarkLine = Color('#FFFFFF1F');

  static const Color shadow = Color('#0E0F1214');

  /// Dialog backdrop and the large dialog shadow.
  static const Color scrim = Color('#0E0F1266');
  static const Color dialogShadow = Color('#0E0F1233');

  // Skeleton loading.
  static const Color skeletonLight = Color('#EDEEF1');
  static const Color skeletonHighlight = Color('#F7F8FA');

  // Pro badge (amber on ink).
  static const Color pro = Color('#F5A524');
  static const Color proInk = Color('#0E0F12');
}
