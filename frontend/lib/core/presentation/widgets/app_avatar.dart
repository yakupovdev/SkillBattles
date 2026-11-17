import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';

/// Diameter and initial size of an [AppAvatar], as used in the design.
enum AppAvatarSize {
  /// 24 — next to an answer on the reveal screen.
  xs(24, 11, 14),

  /// 32 — leaderboard rows.
  row(32, 13, 16),

  /// 36 — top bar.
  sm(36, 14, 18),

  /// 44 — ready check rows.
  md(44, 16, 20),

  /// 48 — live battle header.
  lg(48, 18, 22),

  /// 56 — account settings.
  settings(56, 22, 26),

  /// 72 — profile header.
  xl(72, 28, 34);

  const AppAvatarSize(this.diameter, this.fontSize, this.lineHeight);

  final double diameter;
  final double fontSize;
  final double lineHeight;
}

/// Fill of an [AppAvatar]: blue for the current player, amber for the
/// opponent; ink and grey tell leaderboard places apart.
enum AppAvatarTone { primary, accent, ink, neutral }

/// A round avatar with the first letter of a nickname.
final class AppAvatar extends StatelessComponent {
  const AppAvatar({
    required this.nickname,
    this.size = AppAvatarSize.sm,
    this.tone = AppAvatarTone.primary,
    super.key,
  });

  final String nickname;
  final AppAvatarSize size;
  final AppAvatarTone tone;

  @override
  Component build(BuildContext context) {
    final String initial = nickname.isEmpty ? '?' : String.fromCharCode(nickname.runes.first).toUpperCase();
    final (Color background, Color foreground) = switch (tone) {
      AppAvatarTone.primary => (AppColors.primary, AppColors.white),
      AppAvatarTone.accent => (AppColors.accent, AppColors.ink),
      AppAvatarTone.ink => (AppColors.ink, AppColors.white),
      AppAvatarTone.neutral => (AppColors.border, AppColors.ink),
    };

    return div(
      classes: 'app-avatar',
      styles: Styles(
        width: Unit.pixels(size.diameter),
        height: Unit.pixels(size.diameter),
        color: foreground,
        fontSize: Unit.pixels(size.fontSize),
        lineHeight: Unit.pixels(size.lineHeight),
        backgroundColor: background,
      ),
      attributes: <String, String>{'role': 'img', 'aria-label': nickname},
      <Component>[
        span(attributes: const <String, String>{'aria-hidden': 'true'}, <Component>[Component.text(initial)]),
      ],
    );
  }
}

@css
List<StyleRule> get appAvatarStyles => <StyleRule>[
  css('.app-avatar').styles(
    display: Display.flex,
    radius: const BorderRadius.circular(Unit.percent(50)),
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.center,
    flex: const Flex(shrink: 0),
    fontFamily: AppFonts.display,
    fontWeight: FontWeight.w700,
  ),
];
