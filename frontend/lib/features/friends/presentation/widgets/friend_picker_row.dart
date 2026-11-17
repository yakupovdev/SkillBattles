import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/widgets/app_avatar.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';
import 'package:skill_battles/core/presentation/widgets/pro_badge.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_list_item_entity.dart';

/// One selectable friend of the invitation picker: a 56 px radio row. The
/// whole row is the hit target; a `null` [onTap] makes it inert.
final class FriendPickerRow extends StatelessComponent {
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
  Component build(BuildContext context) {
    final String nickname = friend.friend.nickname;
    return AppTappable(
      onTap: onTap,
      radius: 10,
      isSelected: isSelected,
      semanticLabel: '$nickname, friends since ${DisplayFormatters.date(friend.friendsSince)}',
      classes: isSelected ? 'friend-picker-row friend-picker-row--selected' : 'friend-picker-row',
      child: Component.fragment(<Component>[
        const span(classes: 'friend-picker-row__radio', <Component>[]),
        AppAvatar(nickname: nickname, size: AppAvatarSize.row, tone: AppAvatarTone.accent),
        div(classes: 'friend-picker-row__name', <Component>[
          span(classes: 'friend-picker-row__nickname', <Component>[Component.text(nickname)]),
          if (friend.friend.isPro) const ProBadge(compact: true),
        ]),
        span(classes: 'friend-picker-row__since', <Component>[
          Component.text('Friends since ${_monthDay(friend.friendsSince)}'),
        ]),
      ]),
    );
  }

  /// `Nov 15`, the date without the year.
  static String _monthDay(DateTime value) {
    final String full = DisplayFormatters.date(value);
    return full.substring(0, full.indexOf(','));
  }
}

@css
List<StyleRule> get friendPickerRowStyles => <StyleRule>[
  css('.friend-picker-row').styles(
    display: Display.flex,
    height: const Unit.pixels(56),
    padding: const Padding.symmetric(horizontal: Unit.pixels(17)),
    boxSizing: BoxSizing.borderBox,
    border: Border.all(color: AppColors.border, width: const Unit.pixels(1)),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(12)),
    backgroundColor: AppColors.white,
  ),
  // The 2 px border eats one more pixel of the padding.
  css('.friend-picker-row--selected').styles(
    padding: const Padding.symmetric(horizontal: Unit.pixels(16)),
    border: Border.all(color: AppColors.primary, width: const Unit.pixels(2)),
    backgroundColor: AppColors.primarySurface,
  ),
  css('.friend-picker-row__radio').styles(
    width: const Unit.pixels(18),
    height: const Unit.pixels(18),
    boxSizing: BoxSizing.borderBox,
    border: Border.all(color: AppColors.borderStrong, width: const Unit.pixels(1.5)),
    radius: const BorderRadius.circular(Unit.percent(50)),
    flex: const Flex(shrink: 0),
  ),
  css('.friend-picker-row--selected .friend-picker-row__radio').styles(
    border: Border.all(color: AppColors.primary, width: const Unit.pixels(5)),
  ),
  css('.friend-picker-row__name').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(8)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.friend-picker-row__nickname')
      .styles(
        minWidth: Unit.zero,
        overflow: Overflow.hidden,
        flex: const Flex(grow: 0, shrink: 1, basis: Unit.auto),
        textOverflow: TextOverflow.ellipsis,
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.bodyLg)
      .combine(const Styles(fontWeight: FontWeight.w500)),
  css('.friend-picker-row--selected .friend-picker-row__nickname').styles(fontWeight: FontWeight.w600),
  css('.friend-picker-row__since')
      .styles(flex: const Flex(shrink: 0), whiteSpace: WhiteSpace.noWrap)
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.muted)),
];
