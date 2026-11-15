import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/app/router/app_routes.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/bloc/load_status.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_status_view.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_list_item_entity.dart';
import 'package:skill_battles/features/friends/presentation/bloc/friends_bloc/friends_bloc.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friend_row.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friends_pagination.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friends_sidebar.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friends_skeleton_data.dart';
import 'package:skill_battles/features/friends/presentation/widgets/remove_friend_dialog.dart';

/// "Your friends": the table, its empty and error states and the removal
/// dialog.
final class FriendsListSection extends StatelessWidget {
  const FriendsListSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendsBloc, FriendsState>(
      buildWhen: (FriendsState previous, FriendsState current) =>
          previous.friends != current.friends,
      builder: (BuildContext context, FriendsState state) {
        final FriendsListSlice<FriendListItemEntity> slice = state.friends;
        final bool hasItems = slice.items.isNotEmpty;
        final bool isLoading =
            !hasItems &&
            (slice.loadStatus == LoadStatus.initial ||
                slice.loadStatus.isLoading);
        final bool isEmpty =
            !hasItems && !isLoading && !slice.loadStatus.isFailure;
        final bool hasFailed = !hasItems && slice.loadStatus.isFailure;
        final int total = isLoading
            ? FriendsSkeletonData.friends.page.totalElements
            : slice.totalElements;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Header(
              total: isEmpty || hasFailed ? null : total,
              isLoading: isLoading,
            ),
            if (hasFailed)
              DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: AppErrorView(
                    title: "Couldn't load your friends",
                    message:
                        'Check your connection and try again. Your friends '
                        'are safe; nothing was removed.',
                    onRetry: () => context.read<FriendsBloc>().add(
                      const FriendsListRetryRequested(FriendsList.friends),
                    ),
                  ),
                ),
              )
            else if (isEmpty)
              const _EmptyFriends()
            else ...<Widget>[
              const FriendsTableHeader(),
              Skeletonizer(
                enabled: isLoading,
                child: _Rows(
                  friends: isLoading
                      ? FriendsSkeletonData.friends.items
                      : slice.items,
                ),
              ),
              if (!isLoading && (slice.page?.totalPages ?? 0) > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: FriendsPagination(
                    page: slice.page!,
                    itemCount: slice.items.length,
                    onPageSelected: slice.pageStatus.isLoading
                        ? null
                        : (int page) => context.read<FriendsBloc>().add(
                            FriendsPageRequested(FriendsList.friends, page),
                          ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

final class _Header extends StatelessWidget {
  const _Header({required this.total, required this.isLoading});

  final int? total;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final int? count = total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        spacing: 16,
        children: <Widget>[
          const Expanded(
            child: Text('Your friends', style: AppTextStyles.titleLg),
          ),
          if (count != null)
            Skeletonizer(
              enabled: isLoading,
              child: Text(
                '$count ${count == 1 ? 'friend' : 'friends'} · newest first',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
              ),
            ),
        ],
      ),
    );
  }
}

final class _Rows extends StatelessWidget {
  const _Rows({required this.friends});

  final List<FriendListItemEntity> friends;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final FriendListItemEntity friend in friends)
          FriendRow(
            key: ValueKey<String>(friend.relationshipId),
            friend: friend,
            onOpenProfile: () => context.goNamed(
              AppRoutes.friendProfile.name,
              pathParameters: <String, String>{
                AppRoutes.friendIdParam: friend.friend.id,
              },
              extra: friend.relationshipId,
            ),
            onRemove: () => _confirmRemove(context, friend),
          ),
      ],
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    FriendListItemEntity friend,
  ) {
    final FriendsBloc bloc = context.read<FriendsBloc>();
    return showDialog<void>(
      context: context,
      barrierColor: AppColors.scrim,
      builder: (BuildContext dialogContext) => BlocProvider<FriendsBloc>.value(
        value: bloc,
        child: _RemoveFriendHost(friend: friend),
      ),
    );
  }
}

/// Binds [RemoveFriendDialog] to the removal state of one friend.
final class _RemoveFriendHost extends StatelessWidget {
  const _RemoveFriendHost({required this.friend});

  final FriendListItemEntity friend;

  @override
  Widget build(BuildContext context) {
    final String id = friend.friend.id;
    return BlocConsumer<FriendsBloc, FriendsState>(
      listenWhen: (FriendsState previous, FriendsState current) =>
          previous.friendActions[id]?.status !=
              current.friendActions[id]?.status &&
          (current.friendActions[id]?.status.isSuccess ?? false),
      listener: (BuildContext context, FriendsState state) =>
          Navigator.of(context).pop(),
      buildWhen: (FriendsState previous, FriendsState current) =>
          previous.friendActions[id] != current.friendActions[id],
      builder: (BuildContext context, FriendsState state) {
        final FriendsItemAction? action = state.friendActions[id];
        return RemoveFriendDialog(
          nickname: friend.friend.nickname,
          friendsSince: friend.friendsSince,
          isRemoving: action?.status.isLoading ?? false,
          hasFailed: action?.status.isFailure ?? false,
          onConfirm: () =>
              context.read<FriendsBloc>().add(FriendRemoveRequested(id)),
          onClose: () => Navigator.of(context).pop(),
        );
      },
    );
  }
}

final class _EmptyFriends extends StatelessWidget {
  const _EmptyFriends();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        width: double.infinity,
        // The artboard pads the tile 56 px; the view adds 48.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: AppEmptyView(
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
        ),
      ),
    );
  }
}
