import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_link.dart';

/// Color of an [AppNotice].
enum AppNoticeTone {
  info(AppColors.primaryTint, AppColors.primary, AppColors.inkSoft),
  warning(AppColors.accentSurface, AppColors.accent, AppColors.accentInk),
  danger(AppColors.dangerSurface, AppColors.danger, AppColors.inkSoft),
  success(AppColors.successSurface, AppColors.success, AppColors.inkSoft);

  const AppNoticeTone(this.background, this.dot, this.text);

  final Color background;
  final Color dot;
  final Color text;
}

/// A tinted one-line note with a dot and an optional action link.
final class AppNotice extends StatelessComponent {
  const AppNotice({
    required this.message,
    this.tone = AppNoticeTone.info,
    this.actionLabel,
    this.onAction,
    this.hug = false,
    super.key,
  });

  final String message;
  final AppNoticeTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Whether the note hugs its text (left aligned, 14 px vertical padding)
  /// instead of taking the full width ("Private duels never change your
  /// rating.").
  final bool hug;

  @override
  Component build(BuildContext context) {
    final String? label = actionLabel;
    return div(
      classes: hug ? 'app-notice app-notice--hug' : 'app-notice',
      styles: Styles(backgroundColor: tone.background),
      attributes: const <String, String>{'role': 'status', 'aria-live': 'polite'},
      <Component>[
        AppDot(color: tone.dot),
        p(
          classes: 'app-notice__message',
          styles: Styles(color: tone.text),
          <Component>[Component.text(message)],
        ),
        if (label != null)
          AppTextLink(
            label: label,
            style: AppTextStyles.buttonMd.combine(const Styles(color: AppColors.ink)),
            onPressed: onAction,
          ),
      ],
    );
  }
}

@css
List<StyleRule> get appNoticeStyles => <StyleRule>[
  css('.app-notice').styles(
    display: Display.flex,
    padding: const Padding.symmetric(horizontal: Unit.pixels(16), vertical: Unit.pixels(12)),
    radius: const BorderRadius.circular(Unit.pixels(10)),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(10)),
  ),
  css('.app-notice--hug').styles(
    width: Unit.fitContent,
    maxWidth: const Unit.percent(100),
    padding: const Padding.symmetric(horizontal: Unit.pixels(16), vertical: Unit.pixels(14)),
    alignSelf: AlignSelf.start,
  ),
  css('.app-notice__message')
      .styles(
        minWidth: Unit.zero,
        flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
      )
      .combine(AppTextStyles.bodyMd),
  css('.app-notice--hug .app-notice__message').styles(flex: const Flex(grow: 0, shrink: 1, basis: Unit.auto)),
];
