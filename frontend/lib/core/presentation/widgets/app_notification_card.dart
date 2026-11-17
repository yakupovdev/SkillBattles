import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_shadows.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_avatar.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_countdown_text.dart';
import 'package:skill_battles/core/presentation/widgets/app_deadline_track.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/app_notice.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';

/// An actionable notification floating over the page: an avatar, a title, a
/// body, an optional deadline, two actions and a hide button.
///
/// Knows nothing about what it announces; the owner passes copy, state flags
/// and callbacks. A `null` [onPrimary] / [onSecondary] disables that button;
/// a `null` [onHide] hides the × but keeps its slot. Esc while the focus is
/// inside the card hides it.
final class AppNotificationCard extends StatelessComponent {
  const AppNotificationCard({
    required this.avatarName,
    required this.title,
    required this.text,
    required this.primaryLabel,
    required this.secondaryLabel,
    this.emphasis,
    this.expiresAt,
    this.lifetime = Duration.zero,
    this.clockOffset = Duration.zero,
    this.isExpired = false,
    this.expiredText,
    this.deadlineLabel,
    this.doneText,
    this.warningText,
    this.errorText,
    this.onPrimary,
    this.onSecondary,
    this.isPrimaryLoading = false,
    this.isSecondaryLoading = false,
    this.onHide,
    super.key,
  });

  /// Whose initial the avatar shows.
  final String avatarName;
  final String title;

  /// Highlighted lead of the body (a name), drawn semibold before [text].
  final String? emphasis;
  final String text;

  /// End of the deadline; `null` for a card without a countdown.
  final DateTime? expiresAt;

  /// Full length of the deadline, for the track fill.
  final Duration lifetime;

  /// Server time minus local time.
  final Duration clockOffset;
  final bool isExpired;

  /// Line shown above the actions when [isExpired].
  final String? expiredText;

  /// Replaces the countdown text (`—` when the deadline no longer applies).
  final String? deadlineLabel;

  /// When set the actions are replaced by a success line with this text (a
  /// friend request that was accepted).
  final String? doneText;

  /// Amber note above the actions.
  final String? warningText;

  /// Error under the actions.
  final String? errorText;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;
  final bool isPrimaryLoading;
  final bool isSecondaryLoading;
  final VoidCallback? onHide;

  @override
  Component build(BuildContext context) {
    final DateTime? deadline = expiresAt;
    final String? expired = isExpired ? expiredText : null;
    final String? warning = warningText;
    final String? error = errorText;
    final String? done = doneText;
    final VoidCallback? hide = onHide;

    return div(
      classes: 'app-notification-card',
      attributes: <String, String>{
        'role': 'group',
        'aria-live': 'polite',
        'aria-label': emphasis == null ? '$title. $text' : '$title. $emphasis$text',
      },
      events: hide == null
          ? null
          : <String, void Function(web.Event)>{
              'keydown': (web.Event event) {
                if ((event as web.KeyboardEvent).key != 'Escape') return;
                event.preventDefault();
                hide();
              },
            },
      <Component>[
        _Header(avatarName: avatarName, title: title, emphasis: emphasis, text: text, onHide: onHide),
        if (deadline != null)
          _Deadline(
            expiresAt: deadline,
            lifetime: lifetime,
            clockOffset: clockOffset,
            isExpired: isExpired,
            label: deadlineLabel,
          ),
        if (expired != null) p(classes: 'app-notification-card__line', <Component>[Component.text(expired)]),
        if (warning != null) AppNotice(message: warning, tone: AppNoticeTone.warning),
        if (done != null)
          _DoneLine(text: done)
        else
          div(classes: 'app-notification-card__actions', <Component>[
            AppButton(
              label: primaryLabel,
              onPressed: onPrimary,
              isLoading: isPrimaryLoading,
              size: AppButtonSize.medium,
              expand: true,
            ),
            AppButton(
              label: secondaryLabel,
              onPressed: onSecondary,
              isLoading: isSecondaryLoading,
              variant: AppButtonVariant.outline,
              size: AppButtonSize.medium,
              expand: true,
            ),
          ]),
        if (error != null) AppInlineError(error),
      ],
    );
  }
}

final class _Header extends StatelessComponent {
  const _Header({
    required this.avatarName,
    required this.title,
    required this.emphasis,
    required this.text,
    required this.onHide,
  });

  final String avatarName;
  final String title;
  final String? emphasis;
  final String text;
  final VoidCallback? onHide;

  @override
  Component build(BuildContext context) {
    final String? lead = emphasis;
    final VoidCallback? hide = onHide;
    return div(classes: 'app-notification-card__header', <Component>[
      AppAvatar(nickname: avatarName, size: AppAvatarSize.md, tone: AppAvatarTone.accent),
      div(classes: 'app-notification-card__copy', <Component>[
        p(classes: 'app-notification-card__title', <Component>[Component.text(title)]),
        p(classes: 'app-notification-card__text', <Component>[
          if (lead != null) span(classes: 'app-notification-card__lead', <Component>[Component.text(lead)]),
          span(<Component>[Component.text(text)]),
        ]),
      ]),
      if (hide == null)
        const span(classes: 'app-notification-card__hide-slot', <Component>[])
      else
        AppTappable(
          onTap: hide,
          radius: 24,
          semanticLabel: 'Hide notification',
          classes: 'app-notification-card__hide',
          child: const AppSvgIcon(AppIcons.close, width: 20, height: 20, color: AppColors.muted),
        ),
    ]);
  }
}

final class _Deadline extends StatelessComponent {
  const _Deadline({
    required this.expiresAt,
    required this.lifetime,
    required this.clockOffset,
    required this.isExpired,
    required this.label,
  });

  final DateTime expiresAt;
  final Duration lifetime;
  final Duration clockOffset;
  final bool isExpired;
  final String? label;

  @override
  Component build(BuildContext context) {
    final Styles style = AppTextStyles.monoBodySm.combine(
      Styles(
        color: isExpired ? AppColors.faint : AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
    );
    final String? override = label;
    return div(classes: 'app-notification-card__deadline', <Component>[
      div(classes: 'app-notification-card__track', <Component>[
        AppDeadlineTrack(
          expiresAt: expiresAt,
          lifetime: lifetime,
          clockOffset: clockOffset,
          isExpired: isExpired,
        ),
      ]),
      if (override != null)
        span(styles: style, <Component>[Component.text(override)])
      else
        AppCountdownText(target: expiresAt, clockOffset: clockOffset, suffix: ' left', style: style),
    ]);
  }
}

/// The 48 px success line that replaces the actions of a finished card.
final class _DoneLine extends StatelessComponent {
  const _DoneLine({required this.text});

  final String text;

  @override
  Component build(BuildContext context) {
    return div(classes: 'app-notification-card__done', <Component>[
      const AppSvgIcon(AppIcons.statusSuccess, width: 20, height: 20),
      p(classes: 'app-notification-card__line app-notification-card__done-text', <Component>[Component.text(text)]),
    ]);
  }
}

@css
List<StyleRule> get appNotificationCardStyles => <StyleRule>[
  css('.app-notification-card').styles(
    display: Display.flex,
    padding: const Padding.all(Unit.pixels(21)),
    border: Border.all(color: AppColors.border, width: const Unit.pixels(1)),
    radius: const BorderRadius.circular(Unit.pixels(16)),
    shadow: AppShadows.overlay,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(16)),
    backgroundColor: AppColors.white,
  ),
  css('.app-notification-card__header').styles(
    display: Display.flex,
    alignItems: AlignItems.start,
    gap: const Gap.column(Unit.pixels(14)),
  ),
  css('.app-notification-card__copy').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    padding: const Padding.only(top: Unit.pixels(2)),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(4)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.app-notification-card__title').combine(AppTextStyles.titleSm),
  css('.app-notification-card__text')
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.muted, lineHeight: Unit.pixels(18))),
  css('.app-notification-card__lead').styles(color: AppColors.ink, fontWeight: FontWeight.w600),
  css('.app-notification-card__hide, .app-notification-card__hide-slot').styles(
    display: Display.flex,
    width: const Unit.pixels(48),
    height: const Unit.pixels(48),
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.center,
    flex: const Flex(shrink: 0),
  ),
  css('.app-notification-card__deadline').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(12)),
  ),
  css('.app-notification-card__track').styles(
    minWidth: Unit.zero,
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.app-notification-card__line')
      .combine(AppTextStyles.bodyMd)
      .combine(const Styles(color: AppColors.inkSoft, fontWeight: FontWeight.w500)),
  css('.app-notification-card__actions').styles(display: Display.flex, gap: const Gap.column(Unit.pixels(10))),
  css('.app-notification-card__actions > *').styles(
    minWidth: Unit.zero,
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.app-notification-card__done').styles(
    display: Display.flex,
    height: const Unit.pixels(48),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(12)),
  ),
  css('.app-notification-card__done-text').styles(
    minWidth: Unit.zero,
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
];
