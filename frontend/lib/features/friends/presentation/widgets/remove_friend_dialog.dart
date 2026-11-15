import 'package:material_ui/material_ui.dart';

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
/// [onClose] closes it; the owner pops the route.
final class RemoveFriendDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final VoidCallback? close = isRemoving ? null : onClose;
    return FriendsDialogShell(
      eyebrow: 'Friends since ${DisplayFormatters.date(friendsSince)}',
      title: 'Remove $nickname?',
      onClose: close,
      children: <Widget>[
        Text(
          "You'll disappear from each other's Friends and can't invite each "
          'other to private matches. A pending match invitation between you '
          'is cancelled. You can add each other again later with a friend '
          'code.',
          style: AppTextStyles.bodyMd.copyWith(
            height: 20 / 14,
            color: AppColors.muted,
          ),
        ),
        if (hasFailed && !isRemoving)
          AppInlineError(
            "Couldn't remove $nickname. Check your connection and try again.",
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 10,
          children: <Widget>[
            SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Center(
                  child: AppTextLink(
                    label: 'Cancel',
                    style: AppTextStyles.buttonMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isRemoving ? AppColors.faint : AppColors.muted,
                    ),
                    onPressed: close,
                  ),
                ),
              ),
            ),
            AppButton(
              label: 'Remove friend',
              variant: AppButtonVariant.danger,
              size: AppButtonSize.field,
              isLoading: isRemoving,
              onPressed: onConfirm,
            ),
          ],
        ),
      ],
    );
  }
}
