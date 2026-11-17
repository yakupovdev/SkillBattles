import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/skeleton/skeletonizer.dart';
import 'package:skill_battles/core/presentation/widgets/app_avatar.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/pro_badge.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_profile_entity.dart';

/// Avatar, nickname, Pro badge, "Friends since" and the Remove friend
/// button of a friend profile (Paper: "43 Friend profile — loaded"). The
/// button is hidden while the profile is skeletonized.
final class FriendProfileHeader extends StatelessComponent {
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
  Component build(BuildContext context) {
    return div(classes: 'friend-profile-header', <Component>[
      div(classes: 'friend-profile-header__identity', <Component>[
        AppAvatar(nickname: profile.friend.nickname, size: AppAvatarSize.xl, tone: AppAvatarTone.accent),
        div(classes: 'friend-profile-header__copy', <Component>[
          div(classes: 'friend-profile-header__name-line', <Component>[
            h1(classes: 'friend-profile-header__nickname', <Component>[Component.text(profile.friend.nickname)]),
            if (profile.friend.isPro) const ProBadge(),
          ]),
          p(classes: 'friend-profile-header__since', <Component>[
            Component.text('Friends since ${longDate(profile.friendsSince)}'),
          ]),
        ]),
      ]),
      Skeleton.ignore(
        child: AppButton(
          label: 'Remove friend',
          variant: AppButtonVariant.outline,
          size: AppButtonSize.field,
          onPressed: onRemove,
        ),
      ),
    ]);
  }
}

@css
List<StyleRule> get friendProfileHeaderStyles => <StyleRule>[
  css('.friend-profile-header').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(20)),
  ),
  css('.friend-profile-header__identity').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(20)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.friend-profile-header__copy').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(4)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.friend-profile-header__name-line').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    maxWidth: const Unit.percent(100),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(12)),
  ),
  css('.friend-profile-header__nickname')
      .styles(
        minWidth: Unit.zero,
        overflow: Overflow.hidden,
        flex: const Flex(grow: 0, shrink: 1, basis: Unit.auto),
        textOverflow: TextOverflow.ellipsis,
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.displaySm),
  css('.friend-profile-header__since').combine(AppTextStyles.bodyMd).combine(const Styles(color: AppColors.muted)),
];
