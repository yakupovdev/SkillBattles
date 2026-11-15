import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/widgets/app_avatar.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/pro_badge.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_entity.dart';

/// Which request of a row is in flight.
enum FriendRequestRowAction { accepting, declining, cancelling }

/// One incoming (Accept / Decline) or outgoing (Cancel request) friend
/// request. The in-flight state is per row.
///
/// [now] is the clock of the relative time in the subtitle. A `null` callback
/// disables that button (use it for a mock row while loading).
final class FriendRequestRow extends StatelessWidget {
  const FriendRequestRow({
    required this.request,
    required this.now,
    this.action,
    this.hasFailed = false,
    this.onAccept,
    this.onDecline,
    this.onCancel,
    super.key,
  });

  final RelationshipEntity request;
  final DateTime now;
  final FriendRequestRowAction? action;

  /// The last attempt failed: show the inline error under the row.
  final bool hasFailed;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onCancel;

  static const double _identityIndent = 50;

  @override
  Widget build(BuildContext context) {
    final bool isIncoming = request.isIncoming;
    final bool isBusy = action != null;
    final String subtitle =
        '${isIncoming ? 'Wants to add you' : 'Request sent'} · '
        '${DisplayFormatters.relative(request.createdAt, now)}';
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 6,
          children: <Widget>[
            Row(
              spacing: 14,
              children: <Widget>[
                Expanded(
                  child: _Identity(
                    nickname: request.otherPlayer.nickname,
                    isPro: request.otherPlayer.isPro,
                    subtitle: subtitle,
                  ),
                ),
                if (isIncoming) ...<Widget>[
                  SizedBox(
                    width: 112,
                    child: AppButton(
                      label: 'Accept',
                      size: AppButtonSize.field,
                      expand: true,
                      isLoading: action == FriendRequestRowAction.accepting,
                      onPressed: isBusy ? null : onAccept,
                    ),
                  ),
                  SizedBox(
                    width: 112,
                    child: AppButton(
                      label: 'Decline',
                      variant: AppButtonVariant.outline,
                      size: AppButtonSize.field,
                      expand: true,
                      isLoading: action == FriendRequestRowAction.declining,
                      onPressed: isBusy ? null : onDecline,
                    ),
                  ),
                ] else
                  SizedBox(
                    width: 160,
                    child: AppButton(
                      label: 'Cancel request',
                      variant: AppButtonVariant.outline,
                      size: AppButtonSize.field,
                      expand: true,
                      isLoading: action == FriendRequestRowAction.cancelling,
                      onPressed: isBusy ? null : onCancel,
                    ),
                  ),
              ],
            ),
            if (hasFailed && !isBusy)
              const Padding(
                padding: EdgeInsets.only(left: _identityIndent),
                child: AppInlineError(
                  "Couldn't update the friend request. Try again.",
                ),
              ),
          ],
        ),
      ),
    );
  }
}

final class _Identity extends StatelessWidget {
  const _Identity({
    required this.nickname,
    required this.isPro,
    required this.subtitle,
  });

  final String nickname;
  final bool isPro;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 14,
      children: <Widget>[
        AppAvatar(nickname: nickname, tone: AppAvatarTone.accent),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: <Widget>[
              Row(
                spacing: 8,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      nickname,
                      style: AppTextStyles.bodyLg.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isPro) const ProBadge(),
                ],
              ),
              Text(
                subtitle,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
