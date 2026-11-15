import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_shadows.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_avatar.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_card.dart';
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
/// a `null` [onHide] hides the × but keeps its slot.
final class AppNotificationCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final DateTime? deadline = expiresAt;
    final String? expired = isExpired ? expiredText : null;
    final String? warning = warningText;
    final String? error = errorText;
    final String? done = doneText;
    final VoidCallback? hide = onHide;

    final Widget card = Semantics(
      liveRegion: true,
      container: true,
      label: emphasis == null ? '$title. $text' : '$title. $emphasis$text',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.overlay,
        ),
        child: AppCard(
          color: AppColors.white,
          padding: const EdgeInsets.all(21),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: <Widget>[
              _Header(
                avatarName: avatarName,
                title: title,
                emphasis: emphasis,
                text: text,
                onHide: onHide,
              ),
              if (deadline != null)
                _Deadline(
                  expiresAt: deadline,
                  lifetime: lifetime,
                  clockOffset: clockOffset,
                  isExpired: isExpired,
                  label: deadlineLabel,
                ),
              if (expired != null) _ExpiredLine(text: expired),
              if (warning != null)
                AppNotice(message: warning, tone: AppNoticeTone.warning),
              if (done != null)
                _DoneLine(text: done)
              else
                Row(
                  spacing: 10,
                  children: <Widget>[
                    Expanded(
                      child: AppButton(
                        label: primaryLabel,
                        onPressed: onPrimary,
                        isLoading: isPrimaryLoading,
                        size: AppButtonSize.medium,
                        expand: true,
                      ),
                    ),
                    Expanded(
                      child: AppButton(
                        label: secondaryLabel,
                        onPressed: onSecondary,
                        isLoading: isSecondaryLoading,
                        variant: AppButtonVariant.outline,
                        size: AppButtonSize.medium,
                        expand: true,
                      ),
                    ),
                  ],
                ),
              if (error != null) AppInlineError(error),
            ],
          ),
        ),
      ),
    );
    if (hide == null) return card;
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): hide,
      },
      child: card,
    );
  }
}

final class _Header extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final String? lead = emphasis;
    final VoidCallback? hide = onHide;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 14,
      children: <Widget>[
        AppAvatar(
          nickname: avatarName,
          size: AppAvatarSize.md,
          tone: AppAvatarTone.accent,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: <Widget>[
                Text(title, style: AppTextStyles.titleSm),
                Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      if (lead != null)
                        TextSpan(
                          text: lead,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      TextSpan(text: text),
                    ],
                  ),
                  style: AppTextStyles.bodySm.copyWith(
                    height: 18 / 13,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hide == null)
          const SizedBox.square(dimension: 48)
        else
          _HideButton(onPressed: hide),
      ],
    );
  }
}

final class _HideButton extends StatelessWidget {
  const _HideButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Hide notification',
      button: true,
      excludeSemantics: true,
      child: AppTappable(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: const SizedBox.square(
          dimension: 48,
          child: Center(
            child: AppSvgIcon(
              AppIcons.close,
              width: 20,
              height: 20,
              color: AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

final class _Deadline extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final TextStyle style = AppTextStyles.monoBodySm.copyWith(
      fontWeight: FontWeight.w600,
      color: isExpired ? AppColors.faint : AppColors.primary,
    );
    final String? override = label;
    return Row(
      spacing: 12,
      children: <Widget>[
        Expanded(
          child: AppDeadlineTrack(
            expiresAt: expiresAt,
            lifetime: lifetime,
            clockOffset: clockOffset,
            isExpired: isExpired,
          ),
        ),
        if (override != null)
          Text(override, style: style)
        else
          AppCountdownText(
            target: expiresAt,
            clockOffset: clockOffset,
            suffix: ' left',
            style: style,
          ),
      ],
    );
  }
}

final class _ExpiredLine extends StatelessWidget {
  const _ExpiredLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.bodyMd.copyWith(
        fontWeight: FontWeight.w500,
        color: AppColors.inkSoft,
      ),
    );
  }
}

/// The 48 px success line that replaces the actions of a finished card.
final class _DoneLine extends StatelessWidget {
  const _DoneLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        spacing: 12,
        children: <Widget>[
          const AppSvgIcon(AppIcons.statusSuccess, width: 20, height: 20),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMd.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
