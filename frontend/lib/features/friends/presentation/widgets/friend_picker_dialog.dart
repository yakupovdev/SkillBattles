import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/page_info_entity.dart';
import 'package:skill_battles/core/presentation/skeleton/skeletonizer.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/app_status_view.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_link.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_list_item_entity.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friend_picker_row.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friends_dialog_shell.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friends_pagination.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friends_skeleton_data.dart';

/// Which part of the picker is shown.
enum FriendPickerStatus {
  /// The list is loading: the real rows with mock friends as bones.
  loading,

  /// The list failed to load.
  failed,

  /// The list is ready (it may be empty).
  ready,
}

/// "Invite a friend" dialog of the host's room (Paper: "49 Private room —
/// friend picker"). Presentational: the owner passes the page, the selection
/// and the callbacks, and closes the dialog in [onClose].
///
/// While [isSending] the list is dimmed and locked, Send shows a spinner and
/// the dialog cannot be dismissed. [errorText] is drawn above the actions.
final class FriendPickerDialog extends StatelessComponent {
  const FriendPickerDialog({
    required this.disciplineName,
    required this.status,
    required this.friends,
    required this.page,
    required this.selectedFriendId,
    required this.onSelected,
    required this.onSend,
    required this.onClose,
    required this.onRetry,
    required this.onAddFriends,
    this.onPageSelected,
    this.isChangingPage = false,
    this.isSending = false,
    this.errorText,
    this.pageErrorText,
    super.key,
  });

  final String disciplineName;
  final FriendPickerStatus status;

  /// The friends on the current page.
  final List<FriendListItemEntity> friends;

  /// Paging of the list; `null` until the first page arrived.
  final PageInfoEntity? page;

  /// User id of the selected friend.
  final String? selectedFriendId;
  final ValueChanged<String> onSelected;
  final VoidCallback onSend;
  final VoidCallback onClose;
  final VoidCallback onRetry;

  /// Opens the Friends page from the empty state.
  final VoidCallback onAddFriends;
  final ValueChanged<int>? onPageSelected;

  /// A page change is running: the shown page stays, the pager is off.
  final bool isChangingPage;
  final bool isSending;
  final String? errorText;
  final String? pageErrorText;

  @override
  Component build(BuildContext context) {
    final PageInfoEntity? paging = page;
    final bool isEmpty = status == FriendPickerStatus.ready && friends.isEmpty;
    final bool isReady = status == FriendPickerStatus.ready && !isEmpty;
    final String? error = errorText;
    final String? pageError = pageErrorText;
    return FriendsDialogShell(
      width: 520,
      eyebrow: 'Private duel · $disciplineName',
      title: 'Invite a friend',
      onClose: isSending ? null : onClose,
      children: <Component>[
        p(classes: 'friends-dialog-text', <Component>[
          Component.text(
            'They get a notification anywhere in SkillBattles and have up to a '
            'minute to accept. Accepting brings them into this room.',
          ),
        ]),
        switch (status) {
          FriendPickerStatus.failed => _ListError(onRetry: onRetry),
          FriendPickerStatus.loading => _List(
            friends: FriendsSkeletonData.friends.items,
            isLoading: true,
            selectedFriendId: null,
            isSending: false,
            onSelected: onSelected,
          ),
          FriendPickerStatus.ready =>
            isEmpty
                ? _Empty(onAddFriends: onAddFriends)
                : _List(
                    friends: friends,
                    isLoading: false,
                    selectedFriendId: selectedFriendId,
                    isSending: isSending,
                    onSelected: onSelected,
                  ),
        },
        if (pageError != null) AppInlineError(pageError),
        if (isReady && paging != null && paging.totalPages > 1)
          FriendsPagination(
            page: paging,
            itemCount: friends.length,
            unit: 'friends',
            onPageSelected: isSending || isChangingPage ? null : onPageSelected,
          ),
        if (error != null) AppInlineError(error),
        div(classes: 'friends-dialog-actions', <Component>[
          div(classes: 'friends-dialog-actions__cancel', <Component>[
            AppTextLink(
              label: 'Cancel',
              style: AppTextStyles.buttonMd.combine(
                Styles(color: isSending ? AppColors.faint : AppColors.muted, fontWeight: FontWeight.w500),
              ),
              onPressed: isSending ? null : onClose,
            ),
          ]),
          if (!isEmpty)
            AppButton(
              label: 'Send invitation',
              size: AppButtonSize.field,
              isLoading: isSending,
              onPressed: isReady && selectedFriendId != null ? onSend : null,
            ),
        ]),
      ],
    );
  }
}

final class _List extends StatelessComponent {
  const _List({
    required this.friends,
    required this.isLoading,
    required this.selectedFriendId,
    required this.isSending,
    required this.onSelected,
  });

  final List<FriendListItemEntity> friends;
  final bool isLoading;
  final String? selectedFriendId;
  final bool isSending;
  final ValueChanged<String> onSelected;

  @override
  Component build(BuildContext context) {
    return Skeletonizer(
      enabled: isLoading,
      child: div(
        classes: isSending ? 'friend-picker-list friend-picker-list--locked' : 'friend-picker-list',
        attributes: isSending ? const <String, String>{'inert': ''} : null,
        <Component>[
          for (final FriendListItemEntity item in friends)
            FriendPickerRow(
              key: ValueKey<String>(item.friend.id),
              friend: item,
              isSelected: item.friend.id == selectedFriendId,
              onTap: isLoading || isSending ? null : () => onSelected(item.friend.id),
            ),
        ],
      ),
    );
  }
}

final class _Empty extends StatelessComponent {
  const _Empty({required this.onAddFriends});

  final VoidCallback onAddFriends;

  @override
  Component build(BuildContext context) {
    return div(classes: 'friend-picker-empty', <Component>[
      AppEmptyView(
        title: 'No friends to invite yet',
        message: "Add friends with a friend code, or share this room's code instead.",
        action: AppButton(
          label: 'Add friends',
          variant: AppButtonVariant.dark,
          size: AppButtonSize.medium,
          onPressed: onAddFriends,
        ),
      ),
    ]);
  }
}

final class _ListError extends StatelessComponent {
  const _ListError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Component build(BuildContext context) {
    return AppErrorView(
      title: "Couldn't load your friends.",
      message: 'Check your connection and try again.',
      onRetry: onRetry,
    );
  }
}

@css
List<StyleRule> get friendPickerDialogStyles => <StyleRule>[
  css('.friend-picker-list').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(8)),
  ),
  css('.friend-picker-list--locked').styles(opacity: 0.6, pointerEvents: PointerEvents.none),
  css('.friend-picker-empty').styles(
    display: Display.flex,
    radius: const BorderRadius.circular(Unit.pixels(12)),
    backgroundColor: AppColors.surface,
  ),
];
