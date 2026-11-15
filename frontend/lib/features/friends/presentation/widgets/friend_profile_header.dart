import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_avatar.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/pro_badge.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_profile_entity.dart';

/// Avatar, nickname, Pro badge, "Friends since" and the Remove friend
/// button of a friend profile (Paper: "43 Friend profile — loaded"). The
/// button is hidden while the profile is skeletonized.
final class FriendProfileHeader extends StatelessWidget {
  const FriendProfileHeader({
    required this.profile,
    required this.onRemove,
    super.key,
  });

  final FriendProfileEntity profile;
  final VoidCallback onRemove;

  static const List<String> _months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// `November 15, 2026`.
  static String longDate(DateTime value) {
    final DateTime local = value.toLocal();
    return '${_months[local.month - 1]} ${local.day}, ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 20,
      children: <Widget>[
        Expanded(
          child: Row(
            spacing: 20,
            children: <Widget>[
              AppAvatar(
                nickname: profile.friend.nickname,
                size: AppAvatarSize.xl,
                tone: AppAvatarTone.accent,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: <Widget>[
                    Row(
                      spacing: 12,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            profile.friend.nickname,
                            style: AppTextStyles.displaySm,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (profile.friend.isPro) const ProBadge(),
                      ],
                    ),
                    Text(
                      'Friends since ${longDate(profile.friendsSince)}',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Skeleton.ignore(
          child: AppButton(
            label: 'Remove friend',
            variant: AppButtonVariant.outline,
            size: AppButtonSize.field,
            onPressed: onRemove,
          ),
        ),
      ],
    );
  }
}
