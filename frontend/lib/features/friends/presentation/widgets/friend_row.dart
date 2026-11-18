import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

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
final class FriendsTableHeader extends StatelessComponent {
  const FriendsTableHeader({super.key});

  @override
  Component build(BuildContext context) {
    return div(classes: 'friends-table-header', <Component>[
      p(classes: 'friends-table-header__player', <Component>[Component.text('Player')]),
      p(classes: 'friends-table-lane-since', <Component>[Component.text('Friends since')]),
      const div(classes: 'friends-table-lane-actions', <Component>[]),
    ]);
  }
}

/// One friend: identity (opens the profile), friends since, and the
/// View profile / Remove links.
final class FriendRow extends StatelessComponent {
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
  Component build(BuildContext context) {
    return div(classes: 'friend-row', <Component>[
      div(classes: 'friend-row__player', <Component>[
        AppTappable(
          onTap: onOpenProfile,
          radius: 8,
          semanticLabel: '${friend.friend.nickname}, view profile',
          classes: 'friend-row__identity',
          child: Component.fragment(<Component>[
            AppAvatar(nickname: friend.friend.nickname, tone: AppAvatarTone.accent),
            span(classes: 'friend-row__nickname', <Component>[Component.text(friend.friend.nickname)]),
            if (friend.friend.isPro) const ProBadge(),
          ]),
        ),
      ]),
      p(classes: 'friends-table-lane-since friend-row__since', <Component>[
        Component.text(DisplayFormatters.date(friend.friendsSince)),
      ]),
      div(classes: 'friends-table-lane-actions friend-row__actions', <Component>[
        _RowLink(
          label: 'View profile',
          style: AppTextStyles.buttonMd.combine(const Styles(color: AppColors.ink)),
          onPressed: onOpenProfile,
        ),
        _RowLink(
          label: 'Remove',
          style: AppTextStyles.buttonMd.combine(const Styles(color: AppColors.muted, fontWeight: FontWeight.w500)),
          onPressed: onRemove,
        ),
      ]),
    ]);
  }
}

/// A text link with its 48 px high, 16 px padded hit area.
final class _RowLink extends StatelessComponent {
  const _RowLink({
    required this.label,
    required this.style,
    required this.onPressed,
  });

  final String label;
  final Styles style;
  final VoidCallback onPressed;

  @override
  Component build(BuildContext context) {
    return AppTappable(
      onTap: onPressed,
      radius: 10,
      classes: 'friend-row__link',
      styles: style,
      child: span(<Component>[Component.text(label)]),
    );
  }
}

@css
List<StyleRule> get friendRowStyles => <StyleRule>[
  css('.friends-table-header').styles(
    display: Display.flex,
    padding: const Padding.only(bottom: Unit.pixels(10)),
    border: const Border.only(
      bottom: BorderSide(color: AppColors.divider, width: Unit.pixels(1)),
    ),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(14)),
  ),
  css('.friends-table-header p').combine(AppTextStyles.bodyXs).combine(const Styles(color: AppColors.muted)),
  css('.friends-table-header__player').styles(
    minWidth: Unit.zero,
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.friends-table-lane-since').styles(
    width: const Unit.pixels(FriendsTableLanes.sinceWidth),
    flex: const Flex(shrink: 0),
  ),
  css('.friends-table-lane-actions').styles(
    width: const Unit.pixels(FriendsTableLanes.actionsWidth),
    flex: const Flex(shrink: 0),
  ),
  css('.friend-row').styles(
    display: Display.flex,
    padding: const Padding.symmetric(vertical: Unit.pixels(10)),
    border: const Border.only(
      bottom: BorderSide(color: AppColors.divider, width: Unit.pixels(1)),
    ),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(14)),
  ),
  css('.friend-row__player').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.friend-row__identity').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    maxWidth: const Unit.percent(100),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(14)),
  ),
  css('.friend-row__nickname')
      .styles(
        minWidth: Unit.zero,
        overflow: Overflow.hidden,
        flex: const Flex(grow: 0, shrink: 1, basis: Unit.auto),
        textOverflow: TextOverflow.ellipsis,
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.bodyLg)
      .combine(const Styles(fontWeight: FontWeight.w600)),
  css('.friend-row__since').combine(AppTextStyles.bodyMd).combine(const Styles(color: AppColors.muted)),
  css('.friend-row__actions').styles(
    display: Display.flex,
    justifyContent: JustifyContent.end,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(4)),
  ),
  css('.friend-row__link').styles(
    display: Display.flex,
    height: const Unit.pixels(48),
    padding: const Padding.symmetric(horizontal: Unit.pixels(16)),
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.center,
    whiteSpace: WhiteSpace.noWrap,
  ),
];
