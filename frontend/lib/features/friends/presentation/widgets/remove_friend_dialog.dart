import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_link.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friends_dialog_shell.dart';

/// Destructive confirmation of removing a friend (Paper: "47 Remove friend —
/// confirmation").
///
/// While [isRemoving] the dialog cannot be dismissed and the × is hidden.
/// [onClose] closes it; the owner closes the dialog (`closeAppDialog`).
final class RemoveFriendDialog extends StatelessComponent {
  const RemoveFriendDialog({
    required this.nickname,
    required this.friendsSince,
    required this.onConfirm,
    required this.onClose,
    this.isRemoving = false,
    this.hasFailed = false,
    super.key,
  });

  final String nickname;
  final DateTime friendsSince;
  final VoidCallback onConfirm;
  final VoidCallback onClose;
  final bool isRemoving;
  final bool hasFailed;

  @override
  Component build(BuildContext context) {
    final VoidCallback? close = isRemoving ? null : onClose;
    return FriendsDialogShell(
      eyebrow: 'Friends since ${DisplayFormatters.date(friendsSince)}',
      title: 'Remove $nickname?',
      onClose: close,
      children: <Component>[
        p(classes: 'friends-dialog-text', <Component>[
          Component.text(
            "You'll disappear from each other's Friends and can't invite each "
            'other to private matches. A pending match invitation between you '
            'is cancelled. You can add each other again later with a friend '
            'code.',
          ),
        ]),
        if (hasFailed && !isRemoving) AppInlineError("Couldn't remove $nickname. Check your connection and try again."),
        div(classes: 'friends-dialog-actions', <Component>[
          div(classes: 'friends-dialog-actions__cancel', <Component>[
            AppTextLink(
              label: 'Cancel',
              style: AppTextStyles.buttonMd.combine(
                Styles(color: isRemoving ? AppColors.faint : AppColors.muted, fontWeight: FontWeight.w500),
              ),
              onPressed: close,
            ),
          ]),
          AppButton(
            label: 'Remove friend',
            variant: AppButtonVariant.danger,
            size: AppButtonSize.field,
            isLoading: isRemoving,
            onPressed: onConfirm,
          ),
        ]),
      ],
    );
  }
}
