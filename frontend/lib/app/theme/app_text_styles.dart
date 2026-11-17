import 'package:jaspr/dom.dart';

import 'package:skill_battles/app/theme/app_colors.dart';

/// Font families served from `web/assets/fonts/` (declared in `app_theme.dart`).
abstract final class AppFonts {
  /// Display and headings (Paper: "Space Grotesk").
  static const FontFamily display = FontFamily.list(<FontFamily>[
    FontFamily('SpaceGrotesk'),
    FontFamilies.sansSerif,
  ]);

  /// Body text, labels and buttons (Paper: "Inter").
  static const FontFamily body = FontFamily.list(<FontFamily>[
    FontFamily('Inter'),
    FontFamilies.sansSerif,
  ]);

  /// Numbers, codes, timers and eyebrow labels (Paper: "JetBrains Mono").
  static const FontFamily mono = FontFamily.list(<FontFamily>[
    FontFamily('JetBrainsMono'),
    FontFamilies.monospace,
  ]);
}

/// Text styles of the Paper design as inline [Styles].
///
/// Paper sizes and line heights are px, letter spacing is em. Every style is
/// ink colored; adjust color, weight or line height by combining:
/// `AppTextStyles.bodyMd.combine(const Styles(color: AppColors.muted))`
/// (the later style wins). In `@css` rules use `css('.x').combine(...)`.
abstract final class AppTextStyles {
  /// 104/96 bold, -0.05em. "Victory." on the result screen.
  static const Styles displayXl = Styles(
    fontFamily: AppFonts.display,
    fontSize: Unit.pixels(104),
    fontWeight: FontWeight.w700,
    letterSpacing: Unit.em(-0.05),
    lineHeight: Unit.pixels(96),
    color: AppColors.ink,
  );

  /// 88/84 bold, -0.04em. Auth hero headline.
  static const Styles displayLg = Styles(
    fontFamily: AppFonts.display,
    fontSize: Unit.pixels(88),
    fontWeight: FontWeight.w700,
    letterSpacing: Unit.em(-0.04),
    lineHeight: Unit.pixels(84),
    color: AppColors.ink,
  );

  /// 56/60 bold, -0.035em. Page titles (home, private duel).
  static const Styles displayMd = Styles(
    fontFamily: AppFonts.display,
    fontSize: Unit.pixels(56),
    fontWeight: FontWeight.w700,
    letterSpacing: Unit.em(-0.035),
    lineHeight: Unit.pixels(60),
    color: AppColors.ink,
  );

  /// 44/48 bold, -0.03em. Profile nickname; ranked search title (54 line).
  static const Styles displaySm = Styles(
    fontFamily: AppFonts.display,
    fontSize: Unit.pixels(44),
    fontWeight: FontWeight.w700,
    letterSpacing: Unit.em(-0.03),
    lineHeight: Unit.pixels(48),
    color: AppColors.ink,
  );

  /// 48/52 bold, -0.035em. Account page title.
  static const Styles displayXs = Styles(
    fontFamily: AppFonts.display,
    fontSize: Unit.pixels(48),
    fontWeight: FontWeight.w700,
    letterSpacing: Unit.em(-0.035),
    lineHeight: Unit.pixels(52),
    color: AppColors.ink,
  );

  /// 40/44 bold, -0.03em. Auth form title.
  static const Styles headlineLg = Styles(
    fontFamily: AppFonts.display,
    fontSize: Unit.pixels(40),
    fontWeight: FontWeight.w700,
    letterSpacing: Unit.em(-0.03),
    lineHeight: Unit.pixels(44),
    color: AppColors.ink,
  );

  /// 34/44 semibold, -0.02em. Battle question.
  static const Styles headlineMd = Styles(
    fontFamily: AppFonts.display,
    fontSize: Unit.pixels(34),
    fontWeight: FontWeight.w600,
    letterSpacing: Unit.em(-0.02),
    lineHeight: Unit.pixels(44),
    color: AppColors.ink,
  );

  /// 32/40 bold, -0.02em. Subject card name.
  static const Styles titleXl = Styles(
    fontFamily: AppFonts.display,
    fontSize: Unit.pixels(32),
    fontWeight: FontWeight.w700,
    letterSpacing: Unit.em(-0.02),
    lineHeight: Unit.pixels(40),
    color: AppColors.ink,
  );

  /// 28/34 bold, -0.02em. Discipline card name.
  static const Styles titleXlCompact = Styles(
    fontFamily: AppFonts.display,
    fontSize: Unit.pixels(28),
    fontWeight: FontWeight.w700,
    letterSpacing: Unit.em(-0.02),
    lineHeight: Unit.pixels(34),
    color: AppColors.ink,
  );

  /// 22/28 bold. Section and card titles.
  static const Styles titleLg = Styles(
    fontFamily: AppFonts.display,
    fontSize: Unit.pixels(22),
    fontWeight: FontWeight.w700,
    lineHeight: Unit.pixels(28),
    color: AppColors.ink,
  );

  /// 20/24 bold. Smaller section titles and secondary action titles.
  static const Styles titleMd = Styles(
    fontFamily: AppFonts.display,
    fontSize: Unit.pixels(20),
    fontWeight: FontWeight.w700,
    lineHeight: Unit.pixels(24),
    color: AppColors.ink,
  );

  /// 18/22 bold. Brand wordmark in the top bar.
  static const Styles titleSm = Styles(
    fontFamily: AppFonts.display,
    fontSize: Unit.pixels(18),
    fontWeight: FontWeight.w700,
    lineHeight: Unit.pixels(22),
    color: AppColors.ink,
  );

  /// 18/28 regular. Auth hero paragraph.
  static const Styles bodyXl = Styles(
    fontFamily: AppFonts.body,
    fontSize: Unit.pixels(18),
    fontWeight: FontWeight.w400,
    lineHeight: Unit.pixels(28),
    color: AppColors.ink,
  );

  /// 20/24 medium. Answer option text.
  static const Styles bodyAnswer = Styles(
    fontFamily: AppFonts.body,
    fontSize: Unit.pixels(20),
    fontWeight: FontWeight.w500,
    lineHeight: Unit.pixels(24),
    color: AppColors.ink,
  );

  /// 15/18 regular. Inputs, footers, list titles (600 for names).
  static const Styles bodyLg = Styles(
    fontFamily: AppFonts.body,
    fontSize: Unit.pixels(15),
    fontWeight: FontWeight.w400,
    lineHeight: Unit.pixels(18),
    color: AppColors.ink,
  );

  /// 14/18 regular. Navigation, table cells, secondary text.
  static const Styles bodyMd = Styles(
    fontFamily: AppFonts.body,
    fontSize: Unit.pixels(14),
    fontWeight: FontWeight.w400,
    lineHeight: Unit.pixels(18),
    color: AppColors.ink,
  );

  /// 13/16 regular. Captions, helper and error text, chips.
  static const Styles bodySm = Styles(
    fontFamily: AppFonts.body,
    fontSize: Unit.pixels(13),
    fontWeight: FontWeight.w400,
    lineHeight: Unit.pixels(16),
    color: AppColors.ink,
  );

  /// 12/16 regular. Meta lines and table headers.
  static const Styles bodyXs = Styles(
    fontFamily: AppFonts.body,
    fontSize: Unit.pixels(12),
    fontWeight: FontWeight.w400,
    lineHeight: Unit.pixels(16),
    color: AppColors.ink,
  );

  /// 15/18 semibold. Large button labels.
  static const Styles buttonLg = Styles(
    fontFamily: AppFonts.body,
    fontSize: Unit.pixels(15),
    fontWeight: FontWeight.w600,
    lineHeight: Unit.pixels(18),
    color: AppColors.ink,
  );

  /// 14/18 semibold. Small button labels.
  static const Styles buttonMd = Styles(
    fontFamily: AppFonts.body,
    fontSize: Unit.pixels(14),
    fontWeight: FontWeight.w600,
    lineHeight: Unit.pixels(18),
    color: AppColors.ink,
  );

  /// 52/64 medium, -0.03em. Search timer; private code letters (600, 0).
  static const Styles monoXxl = Styles(
    fontFamily: AppFonts.mono,
    fontSize: Unit.pixels(52),
    fontWeight: FontWeight.w500,
    letterSpacing: Unit.em(-0.03),
    lineHeight: Unit.pixels(64),
    color: AppColors.ink,
  );

  /// 48/48 medium, -0.02em. Day streak on home.
  static const Styles monoStreak = Styles(
    fontFamily: AppFonts.mono,
    fontSize: Unit.pixels(48),
    fontWeight: FontWeight.w500,
    letterSpacing: Unit.em(-0.02),
    lineHeight: Unit.expression('1'),
    color: AppColors.ink,
  );

  /// 44/48 medium, -0.02em. Ratings on subject cards, final scores (600).
  static const Styles monoXl = Styles(
    fontFamily: AppFonts.mono,
    fontSize: Unit.pixels(44),
    fontWeight: FontWeight.w500,
    letterSpacing: Unit.em(-0.02),
    lineHeight: Unit.pixels(48),
    color: AppColors.ink,
  );

  /// 36/44 semibold, -0.02em. Live battle scores; profile ratings (40 line).
  static const Styles monoLg = Styles(
    fontFamily: AppFonts.mono,
    fontSize: Unit.pixels(36),
    fontWeight: FontWeight.w600,
    letterSpacing: Unit.em(-0.02),
    lineHeight: Unit.pixels(44),
    color: AppColors.ink,
  );

  /// 28/34 semibold. Round timer, rating change.
  static const Styles monoMd = Styles(
    fontFamily: AppFonts.mono,
    fontSize: Unit.pixels(28),
    fontWeight: FontWeight.w600,
    lineHeight: Unit.pixels(34),
    color: AppColors.ink,
  );

  /// 22/28 medium. Stat values, join-code input.
  static const Styles monoSm = Styles(
    fontFamily: AppFonts.mono,
    fontSize: Unit.pixels(22),
    fontWeight: FontWeight.w500,
    lineHeight: Unit.pixels(28),
    color: AppColors.ink,
  );

  /// 15/18 semibold. Option letters, rating delta badge.
  static const Styles monoBodyLg = Styles(
    fontFamily: AppFonts.mono,
    fontSize: Unit.pixels(15),
    fontWeight: FontWeight.w600,
    lineHeight: Unit.pixels(18),
    color: AppColors.ink,
  );

  /// 14/18 medium. Rating deltas, scores, rating range.
  static const Styles monoBodyMd = Styles(
    fontFamily: AppFonts.mono,
    fontSize: Unit.pixels(14),
    fontWeight: FontWeight.w500,
    lineHeight: Unit.pixels(18),
    color: AppColors.ink,
  );

  /// 13/16 regular. Countdowns, round numbers (600).
  static const Styles monoBodySm = Styles(
    fontFamily: AppFonts.mono,
    fontSize: Unit.pixels(13),
    fontWeight: FontWeight.w400,
    lineHeight: Unit.pixels(16),
    color: AppColors.ink,
  );

  /// 12/16 regular, +0.08em, upper case. Eyebrow labels ("STEP 1 — ...").
  static const Styles eyebrow = Styles(
    fontFamily: AppFonts.mono,
    fontSize: Unit.pixels(12),
    fontWeight: FontWeight.w400,
    letterSpacing: Unit.em(0.08),
    lineHeight: Unit.pixels(16),
    color: AppColors.muted,
  );

  /// 11/14 regular. Weekday letters, small chips (600–700).
  static const Styles monoCaption = Styles(
    fontFamily: AppFonts.mono,
    fontSize: Unit.pixels(11),
    fontWeight: FontWeight.w400,
    lineHeight: Unit.pixels(14),
    color: AppColors.ink,
  );

  /// 12/16 semibold. WIN / LOSS / DRAW labels.
  static const Styles outcome = Styles(
    fontFamily: AppFonts.mono,
    fontSize: Unit.pixels(12),
    fontWeight: FontWeight.w600,
    lineHeight: Unit.pixels(16),
    color: AppColors.ink,
  );
}
