import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/widgets/app_avatar.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';
import 'package:skill_battles/core/presentation/widgets/pro_badge.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_list_item_entity.dart';

/// Column widths shared by [FriendsTableHeader] and [FriendRow].
abstract final class FriendsTableLanes {
  static const double sinceWidth = 160;
  static const double actionsWidth = 224;
}

/// The header above the friends rows: Player | Friends since | actions lane.
final class FriendsTableHeader extends StatelessWidget {
  const FriendsTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTextStyles.bodyXs.copyWith(
      color: AppColors.muted,
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          spacing: 14,
          children: <Widget>[
            Expanded(child: Text('Player', style: style)),
            SizedBox(
              width: FriendsTableLanes.sinceWidth,
              child: Text('Friends since', style: style),
            ),
            const SizedBox(width: FriendsTableLanes.actionsWidth),
          ],
        ),
      ),
    );
  }
}

/// One friend: identity (opens the profile), friends since, and the
/// View profile / Remove links.
final class FriendRow extends StatelessWidget {
  const FriendRow({
    required this.friend,
    required this.onOpenProfile,
    required this.onRemove,
    super.key,
  });

  final FriendListItemEntity friend;
  final VoidCallback onOpenProfile;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          spacing: 14,
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppTappable(
                  onTap: onOpenProfile,
                  borderRadius: BorderRadius.circular(8),
                  semanticLabel: '${friend.friend.nickname}, view profile',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 14,
                    children: <Widget>[
                      AppAvatar(
                        nickname: friend.friend.nickname,
                        tone: AppAvatarTone.accent,
                      ),
                      Flexible(
                        child: Text(
                          friend.friend.nickname,
                          style: AppTextStyles.bodyLg.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (friend.friend.isPro) const ProBadge(),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: FriendsTableLanes.sinceWidth,
              child: Text(
                DisplayFormatters.date(friend.friendsSince),
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.muted),
              ),
            ),
            SizedBox(
              width: FriendsTableLanes.actionsWidth,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 4,
                children: <Widget>[
                  _RowLink(
                    label: 'View profile',
                    style: AppTextStyles.buttonMd.copyWith(
                      color: AppColors.ink,
                    ),
                    onPressed: onOpenProfile,
                  ),
                  _RowLink(
                    label: 'Remove',
                    style: AppTextStyles.buttonMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                    ),
                    onPressed: onRemove,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A text link with its 48 px high, 16 px padded hit area.
final class _RowLink extends StatelessWidget {
  const _RowLink({
    required this.label,
    required this.style,
    required this.onPressed,
  });

  final String label;
  final TextStyle style;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppTappable(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(child: Text(label, style: style)),
        ),
      ),
    );
  }
}
