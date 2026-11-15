import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/bloc/load_status.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/app_segmented_control.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_request_direction.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_entity.dart';
import 'package:skill_battles/features/friends/presentation/bloc/friends_bloc/friends_bloc.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friend_request_row.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friends_pagination.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friends_skeleton_data.dart';

/// Incoming / outgoing friend requests with the switch above them. Each
/// direction is its own paged list in [FriendsBloc]; [direction] is the
/// screen's local choice.
final class FriendsRequestsSection extends StatelessWidget {
  const FriendsRequestsSection({
    required this.direction,
    required this.onDirectionSelected,
    super.key,
  });

  final FriendRequestDirection direction;
  final ValueChanged<FriendRequestDirection> onDirectionSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            spacing: 16,
            children: <Widget>[
              const Expanded(
                child: Text('Requests', style: AppTextStyles.titleLg),
              ),
              AppSegmentedControl<FriendRequestDirection>(
                size: AppSegmentedControlSize.small,
                selected: direction,
                onSelected: onDirectionSelected,
                segments: const <AppSegment<FriendRequestDirection>>[
                  AppSegment<FriendRequestDirection>(
                    value: FriendRequestDirection.incoming,
                    label: 'Incoming',
                  ),
                  AppSegment<FriendRequestDirection>(
                    value: FriendRequestDirection.outgoing,
                    label: 'Outgoing',
                  ),
                ],
              ),
            ],
          ),
        ),
        _RequestsBody(direction: direction),
      ],
    );
  }
}

final class _RequestsBody extends StatelessWidget {
  const _RequestsBody({required this.direction});

  final FriendRequestDirection direction;

  @override
  Widget build(BuildContext context) {
    final FriendsList list = direction == FriendRequestDirection.incoming
        ? FriendsList.incoming
        : FriendsList.outgoing;
    return BlocBuilder<FriendsBloc, FriendsState>(
      buildWhen: (FriendsState previous, FriendsState current) =>
          previous.slice(list) != current.slice(list) ||
          previous.requestActions != current.requestActions,
      builder: (BuildContext context, FriendsState state) {
        final FriendsListSlice<RelationshipEntity> slice =
            direction == FriendRequestDirection.incoming
            ? state.incoming
            : state.outgoing;
        final bool hasItems = slice.items.isNotEmpty;
        if (slice.loadStatus.isFailure && !hasItems) {
          return _RequestsError(
            onRetry: () => context.read<FriendsBloc>().add(
              FriendsListRetryRequested(list),
            ),
          );
        }
        final bool isLoading =
            !hasItems &&
            (slice.loadStatus == LoadStatus.initial ||
                slice.loadStatus.isLoading);
        if (!isLoading && !hasItems) {
          return _EmptyRequests(direction: direction);
        }
        final List<RelationshipEntity> items = isLoading
            ? FriendsSkeletonData.requests(direction).items
            : slice.items;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: <Widget>[
            Skeletonizer(
              enabled: isLoading,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final RelationshipEntity request in items)
                    _RequestRowHost(
                      key: ValueKey<String>(request.id),
                      request: request,
                      action: isLoading
                          ? null
                          : state.requestActions[request.id],
                    ),
                ],
              ),
            ),
            if (!isLoading && (slice.page?.totalPages ?? 0) > 1)
              FriendsPagination(
                page: slice.page!,
                itemCount: items.length,
                onPageSelected: slice.pageStatus.isLoading
                    ? null
                    : (int page) => context.read<FriendsBloc>().add(
                        FriendsPageRequested(list, page),
                      ),
              ),
          ],
        );
      },
    );
  }
}

/// A request row that remembers which button was tapped, since the BLoC only
/// reports that the request is loading.
final class _RequestRowHost extends StatefulWidget {
  const _RequestRowHost({
    required this.request,
    required this.action,
    super.key,
  });

  final RelationshipEntity request;
  final FriendsItemAction? action;

  @override
  State<_RequestRowHost> createState() => _RequestRowHostState();
}

final class _RequestRowHostState extends State<_RequestRowHost> {
  late FriendRequestRowAction _tapped;

  @override
  void initState() {
    super.initState();
    _tapped = widget.request.isIncoming
        ? FriendRequestRowAction.accepting
        : FriendRequestRowAction.cancelling;
  }

  void _send(FriendRequestRowAction action, FriendsEvent event) {
    _tapped = action;
    context.read<FriendsBloc>().add(event);
  }

  @override
  Widget build(BuildContext context) {
    final FriendsItemAction? action = widget.action;
    final String id = widget.request.id;
    return FriendRequestRow(
      request: widget.request,
      now: DateTime.now(),
      action: action != null && action.status.isLoading ? _tapped : null,
      hasFailed: action != null && action.status.isFailure,
      onAccept: () => _send(
        FriendRequestRowAction.accepting,
        FriendRequestAcceptRequested(id),
      ),
      onDecline: () => _send(
        FriendRequestRowAction.declining,
        FriendRequestDeclineRequested(id),
      ),
      onCancel: () => _send(
        FriendRequestRowAction.cancelling,
        FriendRequestCancelRequested(id),
      ),
    );
  }
}

final class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests({required this.direction});

  final FriendRequestDirection direction;

  @override
  Widget build(BuildContext context) {
    final bool isIncoming = direction == FriendRequestDirection.incoming;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: <Widget>[
            Text(
              isIncoming ? 'No incoming requests' : 'No outgoing requests',
              style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              isIncoming
                  ? 'When someone enters your friend code, their request '
                        'shows up here and as a notification.'
                  : 'Requests you send with a friend code wait here until '
                        "they're answered.",
              style: AppTextStyles.bodySm.copyWith(
                height: 18 / 13,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _RequestsError extends StatelessWidget {
  const _RequestsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          spacing: 16,
          children: <Widget>[
            const Expanded(
              child: AppInlineError(
                "Couldn't load your requests. Check your connection and try "
                'again.',
              ),
            ),
            AppButton(
              label: 'Try again',
              variant: AppButtonVariant.outline,
              size: AppButtonSize.field,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
