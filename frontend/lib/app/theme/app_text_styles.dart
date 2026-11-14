import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';

/// Font families bundled from `assets/fonts/` (see `pubspec.yaml`).
abstract final class AppFonts {
  /// Display and headings (Paper: "Space Grotesk").
  static const String display = 'SpaceGrotesk';

  /// Body text, labels and buttons (Paper: "Inter").
  static const String body = 'Inter';

  /// Numbers, codes, timers and eyebrow labels (Paper: "JetBrains Mono").
  static const String mono = 'JetBrainsMono';
}

/// Text styles of the Paper design.
///
/// Paper sizes are px, line heights are px (converted to a `height` factor),
/// and letter spacing is em (converted to logical pixels). Every style is ink
/// colored; adjust color, weight or line height with `copyWith` where a
/// screen deviates.
abstract final class AppTextStyles {
  // Display — Space Grotesk.

  /// 104/96 bold, -0.05em. "Victory." on the result screen.
  static const TextStyle displayXl = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 104,
    height: 96 / 104,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.05 * 104,
    color: AppColors.ink,
  );

  /// 88/84 bold, -0.04em. Auth hero headline.
  static const TextStyle displayLg = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 88,
    height: 84 / 88,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.04 * 88,
    color: AppColors.ink,
  );

  /// 56/60 bold, -0.035em. Page titles (home, private duel).
  static const TextStyle displayMd = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 56,
    height: 60 / 56,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.035 * 56,
    color: AppColors.ink,
  );

  /// 44/48 bold, -0.03em. Profile nickname; ranked search title (54 line).
  static const TextStyle displaySm = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 44,
    height: 48 / 44,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.03 * 44,
    color: AppColors.ink,
  );

  /// 48/52 bold, -0.035em. Account page title.
  static const TextStyle displayXs = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 48,
    height: 52 / 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.035 * 48,
    color: AppColors.ink,
  );

  /// 40/44 bold, -0.03em. Auth form title.
  static const TextStyle headlineLg = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 40,
    height: 44 / 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.03 * 40,
    color: AppColors.ink,
  );

  /// 34/44 semibold, -0.02em. Battle question.
  static const TextStyle headlineMd = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 34,
    height: 44 / 34,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.02 * 34,
    color: AppColors.ink,
  );

  /// 32/40 bold, -0.02em. Subject card name.
  static const TextStyle titleXl = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.02 * 32,
    color: AppColors.ink,
  );

  /// 28/34 bold, -0.02em. Discipline card name.
  static const TextStyle titleXlCompact = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.02 * 28,
    color: AppColors.ink,
  );

  /// 22/28 bold. Section and card titles.
  static const TextStyle titleLg = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  /// 20/24 bold. Smaller section titles and secondary action titles.
  static const TextStyle titleMd = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 20,
    height: 24 / 20,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  /// 18/22 bold. Brand wordmark in the top bar.
  static const TextStyle titleSm = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 18,
    height: 22 / 18,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  // Body — Inter.

  /// 18/28 regular. Auth hero paragraph.
  static const TextStyle bodyXl = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 18,
    height: 28 / 18,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
  );

  /// 20/24 medium. Answer option text.
  static const TextStyle bodyAnswer = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 20,
    height: 24 / 20,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
  );

  /// 15/18 regular. Inputs, footers, list titles (600 for names).
  static const TextStyle bodyLg = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 15,
    height: 18 / 15,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
  );

  /// 14/18 regular. Navigation, table cells, secondary text.
  static const TextStyle bodyMd = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    height: 18 / 14,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
  );

  /// 13/16 regular. Captions, helper and error text, chips.
  static const TextStyle bodySm = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 13,
    height: 16 / 13,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
  );

  /// 12/16 regular. Meta lines and table headers.
  static const TextStyle bodyXs = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
  );

  /// 15/18 semibold. Large button labels.
  static const TextStyle buttonLg = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 15,
    height: 18 / 15,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  /// 14/18 semibold. Small button labels.
  static const TextStyle buttonMd = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    height: 18 / 14,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  // Mono — JetBrains Mono.

  /// 52/64 medium, -0.03em. Search timer; private code letters (600, 0).
  static const TextStyle monoXxl = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 52,
    height: 64 / 52,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.03 * 52,
    color: AppColors.ink,
  );

  /// 48/48 medium, -0.02em. Day streak on home.
  static const TextStyle monoStreak = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 48,
    height: 1,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.02 * 48,
    color: AppColors.ink,
  );

  /// 44/48 medium, -0.02em. Ratings on subject cards, final scores (600).
  static const TextStyle monoXl = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 44,
    height: 48 / 44,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.02 * 44,
    color: AppColors.ink,
  );

  /// 36/44 semibold, -0.02em. Live battle scores; profile ratings (40 line).
  static const TextStyle monoLg = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 36,
    height: 44 / 36,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.02 * 36,
    color: AppColors.ink,
  );

  /// 28/34 semibold. Round timer, rating change.
  static const TextStyle monoMd = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  /// 22/28 medium. Stat values, join-code input.
  static const TextStyle monoSm = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
  );

  /// 15/18 semibold. Option letters, rating delta badge.
  static const TextStyle monoBodyLg = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 15,
    height: 18 / 15,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  /// 14/18 medium. Rating deltas, scores, rating range.
  static const TextStyle monoBodyMd = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 14,
    height: 18 / 14,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
  );

  /// 13/16 regular. Countdowns, round numbers (600).
  static const TextStyle monoBodySm = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 13,
    height: 16 / 13,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
  );

  /// 12/16 regular, +0.08em, upper case. Eyebrow labels ("STEP 1 — ...").
  static const TextStyle eyebrow = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.08 * 12,
    color: AppColors.muted,
  );

  /// 11/14 regular. Weekday letters, small chips (600–700).
  static const TextStyle monoCaption = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
  );

  /// 12/16 semibold. WIN / LOSS / DRAW labels.
  static const TextStyle outcome = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );
}
