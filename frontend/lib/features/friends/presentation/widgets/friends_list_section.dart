import 'package:bloc_signals_jaspr/bloc_signals_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/router/app_routes.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/bloc/load_status.dart';
import 'package:skill_battles/core/presentation/overlay/app_overlay.dart';
import 'package:skill_battles/core/presentation/skeleton/skeletonizer.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/app_status_view.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_list_item_entity.dart';
import 'package:skill_battles/features/friends/presentation/bloc/friends_bloc/friends_bloc.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friend_row.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friends_pagination.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friends_sidebar.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friends_skeleton_data.dart';
import 'package:skill_battles/features/friends/presentation/widgets/remove_friend_dialog.dart';

/// "Your friends": the table, its empty and error states and the removal
/// dialog.
final class FriendsListSection extends StatelessComponent {
  const FriendsListSection({super.key});

  @override
  Component build(BuildContext context) {
    return BlocSignalBuilder<FriendsBloc, FriendsState>(
      buildWhen: (FriendsState previous, FriendsState current) => previous.friends != current.friends,
      builder: (BuildContext context, FriendsState state) {
        final FriendsListSlice<FriendListItemEntity> slice = state.friends;
        final bool hasItems = slice.items.isNotEmpty;
        final bool isLoading = !hasItems && (slice.loadStatus == LoadStatus.initial || slice.loadStatus.isLoading);
        final bool isEmpty = !hasItems && !isLoading && !slice.loadStatus.isFailure;
        final bool hasFailed = !hasItems && slice.loadStatus.isFailure;
        final int total = isLoading ? FriendsSkeletonData.friends.page.totalElements : slice.totalElements;
        return section(classes: 'friends-list', <Component>[
          _Header(total: isEmpty || hasFailed ? null : total, isLoading: isLoading),
          if (hasFailed)
            div(classes: 'friends-list__error', <Component>[
              AppErrorView(
                title: "Couldn't load your friends",
                message:
                    'Check your connection and try again. Your friends '
                    'are safe; nothing was removed.',
                onRetry: () => context.read<FriendsBloc>().add(const FriendsListRetryRequested(FriendsList.friends)),
              ),
            ])
          else if (isEmpty)
            const _EmptyFriends()
          else ...<Component>[
            const FriendsTableHeader(),
            Skeletonizer(
              enabled: isLoading,
              child: _Rows(friends: isLoading ? FriendsSkeletonData.friends.items : slice.items),
            ),
            if (slice.pageStatus.isFailure && slice.pageFailure != null)
              div(classes: 'friends-list__page-error', <Component>[AppInlineError(slice.pageFailure!.userMessage)]),
            if (!isLoading && (slice.page?.totalPages ?? 0) > 1)
              div(classes: 'friends-list__pagination', <Component>[
                FriendsPagination(
                  page: slice.page!,
                  itemCount: slice.items.length,
                  onPageSelected: slice.loadStatus.isLoading || slice.pageStatus.isLoading
                      ? null
                      : (int page) => context.read<FriendsBloc>().add(FriendsPageRequested(FriendsList.friends, page)),
                ),
              ]),
          ],
        ]);
      },
    );
  }
}

final class _Header extends StatelessComponent {
  const _Header({required this.total, required this.isLoading});

  final int? total;
  final bool isLoading;

  @override
  Component build(BuildContext context) {
    final int? count = total;
    return div(classes: 'friends-list__header', <Component>[
      h2(classes: 'friends-list__title', <Component>[Component.text('Your friends')]),
      if (count != null)
        Skeletonizer(
          enabled: isLoading,
          child: span(classes: 'friends-list__count', <Component>[
            Component.text('$count ${count == 1 ? 'friend' : 'friends'} · newest first'),
          ]),
        ),
    ]);
  }
}

final class _Rows extends StatelessComponent {
  const _Rows({required this.friends});

  final List<FriendListItemEntity> friends;

  @override
  Component build(BuildContext context) {
    return div(classes: 'friends-list__rows', <Component>[
      for (final FriendListItemEntity friend in friends)
        FriendRow(
          key: ValueKey<String>(friend.relationshipId),
          friend: friend,
          onOpenProfile: () => context.goNamed(
            AppRoutes.friendProfile.name,
            pathParameters: <String, String>{AppRoutes.friendIdParam: friend.friend.id},
            extra: friend.relationshipId,
          ),
          onRemove: () => _confirmRemove(context, friend),
        ),
    ]);
  }

  Future<void> _confirmRemove(BuildContext context, FriendListItemEntity friend) {
    final FriendsBloc bloc = context.read<FriendsBloc>();
    return showAppDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => BlocSignalProvider<FriendsBloc>.value(
        value: bloc,
        child: _RemoveFriendHost(friend: friend),
      ),
    );
  }
}

/// Binds [RemoveFriendDialog] to the removal state of one friend.
final class _RemoveFriendHost extends StatelessComponent {
  const _RemoveFriendHost({required this.friend});

  final FriendListItemEntity friend;

  @override
  Component build(BuildContext context) {
    final String id = friend.friend.id;
    return BlocSignalConsumer<FriendsBloc, FriendsState>(
      listenWhen: (FriendsState previous, FriendsState current) =>
          previous.friendActions[id]?.status != current.friendActions[id]?.status &&
          (current.friendActions[id]?.status.isSuccess ?? false),
      listener: (BuildContext context, FriendsState state) => closeAppDialog<void>(context),
      buildWhen: (FriendsState previous, FriendsState current) =>
          previous.friendActions[id] != current.friendActions[id],
      builder: (BuildContext context, FriendsState state) {
        final FriendsItemAction? action = state.friendActions[id];
        return RemoveFriendDialog(
          nickname: friend.friend.nickname,
          friendsSince: friend.friendsSince,
          isRemoving: action?.status.isLoading ?? false,
          hasFailed: action?.status.isFailure ?? false,
          onConfirm: () => context.read<FriendsBloc>().add(FriendRemoveRequested(id)),
          onClose: () => closeAppDialog<void>(context),
        );
      },
    );
  }
}

final class _EmptyFriends extends StatelessComponent {
  const _EmptyFriends();

  @override
  Component build(BuildContext context) {
    // The artboard pads the tile 56 px; the view adds 48.
    return div(classes: 'friends-list__empty', <Component>[
      AppEmptyView(
        title: 'No friends yet',
        message:
            "Share your friend code, or enter a friend's code on the right. "
            'Once they accept, you can invite each other to private '
            'matches.',
        action: AppButton(
          label: 'Copy your friend code',
          variant: AppButtonVariant.outline,
          size: AppButtonSize.medium,
          onPressed: () => copyFriendCode(context),
        ),
      ),
    ]);
  }
}

@css
List<StyleRule> get friendsListSectionStyles => <StyleRule>[
  css('.friends-list').styles(display: Display.flex, flexDirection: FlexDirection.column),
  css('.friends-list__header').styles(
    display: Display.flex,
    padding: const Padding.only(bottom: Unit.pixels(16)),
    alignItems: AlignItems.baseline,
    gap: const Gap.column(Unit.pixels(16)),
  ),
  css('.friends-list__title')
      .styles(
        minWidth: Unit.zero,
        flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
      )
      .combine(AppTextStyles.titleLg),
  css('.friends-list__count').combine(AppTextStyles.bodySm).combine(const Styles(color: AppColors.muted)),
  css('.friends-list__error').styles(
    display: Display.flex,
    padding: const Padding.symmetric(vertical: Unit.pixels(8)),
    border: const Border.only(
      top: BorderSide(color: AppColors.border, width: Unit.pixels(1)),
    ),
  ),
  css('.friends-list__rows').styles(display: Display.flex, flexDirection: FlexDirection.column),
  css('.friends-list__page-error').styles(padding: const Padding.only(top: Unit.pixels(12))),
  css('.friends-list__pagination').styles(padding: const Padding.only(top: Unit.pixels(16))),
  css('.friends-list__empty').styles(
    display: Display.flex,
    padding: const Padding.symmetric(vertical: Unit.pixels(8)),
    radius: const BorderRadius.circular(Unit.pixels(16)),
    backgroundColor: AppColors.surface,
  ),
];
