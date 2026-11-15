import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/widgets/app_avatar.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';
import 'package:skill_battles/core/presentation/widgets/pro_badge.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_list_item_entity.dart';

/// One selectable friend of the invitation picker: a 56 px radio row. The
/// whole row is the hit target; a `null` [onTap] makes it inert.
final class FriendPickerRow extends StatelessWidget {
  const FriendPickerRow({
    required this.friend,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final FriendListItemEntity friend;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final String nickname = friend.friend.nickname;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: isSelected,
      child: AppTappable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        isSelected: isSelected,
        semanticLabel:
            '$nickname, friends since ${DisplayFormatters.date(friend.friendsSince)}',
        child: Container(
          height: 56,
          padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 17),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySurface : AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            spacing: 12,
            children: <Widget>[
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.borderStrong,
                    width: isSelected ? 5 : 1.5,
                  ),
                ),
              ),
              AppAvatar(
                nickname: nickname,
                size: AppAvatarSize.row,
                tone: AppAvatarTone.accent,
              ),
              Expanded(
                child: Row(
                  spacing: 8,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        nickname,
                        style: AppTextStyles.bodyLg.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (friend.friend.isPro) const ProBadge(compact: true),
                  ],
                ),
              ),
              Text(
                'Friends since ${_monthDay(friend.friendsSince)}',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// `Nov 15`, the date without the year.
  static String _monthDay(DateTime value) {
    final String full = DisplayFormatters.date(value);
    return full.substring(0, full.indexOf(','));
  }
}
