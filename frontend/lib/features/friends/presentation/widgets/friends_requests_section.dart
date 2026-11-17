import 'package:bloc_signals_jaspr/bloc_signals_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/bloc/load_status.dart';
import 'package:skill_battles/core/presentation/skeleton/skeletonizer.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/app_segmented_control.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_request_direction.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_entity.dart';
import 'package:skill_battles/features/friends/presentation/bloc/friends_bloc/friends_bloc.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friend_request_row.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friends_pagination.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friends_skeleton_data.dart';

/// Incoming / outgoing friend requests with the switch above them. Each
/// direction is its own paged list in [FriendsBloc]; [direction] is the
/// screen's local choice.
final class FriendsRequestsSection extends StatelessComponent {
  const FriendsRequestsSection({
    required this.direction,
    required this.onDirectionSelected,
    super.key,
  });

  final FriendRequestDirection direction;
  final ValueChanged<FriendRequestDirection> onDirectionSelected;

  @override
  Component build(BuildContext context) {
    return section(classes: 'friends-requests', <Component>[
      div(classes: 'friends-requests__header', <Component>[
        h2(classes: 'friends-requests__title', <Component>[Component.text('Requests')]),
        AppSegmentedControl<FriendRequestDirection>(
          size: AppSegmentedControlSize.small,
          selected: direction,
          onSelected: onDirectionSelected,
          segments: const <AppSegment<FriendRequestDirection>>[
            AppSegment<FriendRequestDirection>(value: FriendRequestDirection.incoming, label: 'Incoming'),
            AppSegment<FriendRequestDirection>(value: FriendRequestDirection.outgoing, label: 'Outgoing'),
          ],
        ),
      ]),
      _RequestsBody(direction: direction),
    ]);
  }
}

final class _RequestsBody extends StatelessComponent {
  const _RequestsBody({required this.direction});

  final FriendRequestDirection direction;

  @override
  Component build(BuildContext context) {
    final FriendsList list = direction == FriendRequestDirection.incoming ? FriendsList.incoming : FriendsList.outgoing;
    return BlocSignalBuilder<FriendsBloc, FriendsState>(
      // A direction change must read updates filtered out by buildWhen.
      key: ValueKey<FriendsList>(list),
      buildWhen: (FriendsState previous, FriendsState current) =>
          previous.slice(list) != current.slice(list) || previous.requestActions != current.requestActions,
      builder: (BuildContext context, FriendsState state) {
        final FriendsListSlice<RelationshipEntity> slice = direction == FriendRequestDirection.incoming
            ? state.incoming
            : state.outgoing;
        final bool hasItems = slice.items.isNotEmpty;
        if (slice.loadStatus.isFailure && !hasItems) {
          return _RequestsError(
            onRetry: () => context.read<FriendsBloc>().add(FriendsListRetryRequested(list)),
          );
        }
        final bool isLoading = !hasItems && (slice.loadStatus == LoadStatus.initial || slice.loadStatus.isLoading);
        if (!isLoading && !hasItems) {
          return _EmptyRequests(direction: direction);
        }
        final List<RelationshipEntity> items = isLoading ? FriendsSkeletonData.requests(direction).items : slice.items;
        return div(classes: 'friends-requests__body', <Component>[
          Skeletonizer(
            enabled: isLoading,
            child: div(classes: 'friends-requests__rows', <Component>[
              for (final RelationshipEntity request in items)
                _RequestRowHost(
                  key: ValueKey<String>(request.id),
                  request: request,
                  action: isLoading ? null : state.requestActions[request.id],
                ),
            ]),
          ),
          if (slice.pageStatus.isFailure && slice.pageFailure != null) AppInlineError(slice.pageFailure!.userMessage),
          if (!isLoading && (slice.page?.totalPages ?? 0) > 1)
            FriendsPagination(
              page: slice.page!,
              itemCount: items.length,
              onPageSelected: slice.loadStatus.isLoading || slice.pageStatus.isLoading
                  ? null
                  : (int page) => context.read<FriendsBloc>().add(FriendsPageRequested(list, page)),
            ),
        ]);
      },
    );
  }
}

/// A request row that remembers which button was tapped, since the BLoC only
/// reports that the request is loading.
final class _RequestRowHost extends StatefulComponent {
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
    _tapped = component.request.isIncoming ? FriendRequestRowAction.accepting : FriendRequestRowAction.cancelling;
  }

  void _send(FriendRequestRowAction action, FriendsEvent event) {
    _tapped = action;
    context.read<FriendsBloc>().add(event);
  }

  @override
  Component build(BuildContext context) {
    final FriendsItemAction? action = component.action;
    final String id = component.request.id;
    return FriendRequestRow(
      request: component.request,
      now: DateTime.now(),
      action: action != null && action.status.isLoading ? _tapped : null,
      hasFailed: action != null && action.status.isFailure,
      onAccept: () => _send(FriendRequestRowAction.accepting, FriendRequestAcceptRequested(id)),
      onDecline: () => _send(FriendRequestRowAction.declining, FriendRequestDeclineRequested(id)),
      onCancel: () => _send(FriendRequestRowAction.cancelling, FriendRequestCancelRequested(id)),
    );
  }
}

final class _EmptyRequests extends StatelessComponent {
  const _EmptyRequests({required this.direction});

  final FriendRequestDirection direction;

  @override
  Component build(BuildContext context) {
    final bool isIncoming = direction == FriendRequestDirection.incoming;
    return div(classes: 'friends-requests__empty', <Component>[
      p(classes: 'friends-requests__empty-title', <Component>[
        Component.text(isIncoming ? 'No incoming requests' : 'No outgoing requests'),
      ]),
      p(classes: 'friends-requests__empty-text', <Component>[
        Component.text(
          isIncoming
              ? 'When someone enters your friend code, their request '
                    'shows up here and as a notification.'
              : 'Requests you send with a friend code wait here until '
                    "they're answered.",
        ),
      ]),
    ]);
  }
}

final class _RequestsError extends StatelessComponent {
  const _RequestsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Component build(BuildContext context) {
    return div(classes: 'friends-requests__error', <Component>[
      const AppInlineError(
        "Couldn't load your requests. Check your connection and try "
        'again.',
      ),
      AppButton(
        label: 'Try again',
        variant: AppButtonVariant.outline,
        size: AppButtonSize.field,
        onPressed: onRetry,
      ),
    ]);
  }
}

@css
List<StyleRule> get friendsRequestsSectionStyles => <StyleRule>[
  css('.friends-requests').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(8)),
  ),
  css('.friends-requests__header').styles(
    display: Display.flex,
    padding: const Padding.only(bottom: Unit.pixels(8)),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(16)),
  ),
  css('.friends-requests__title')
      .styles(
        minWidth: Unit.zero,
        flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
      )
      .combine(AppTextStyles.titleLg),
  css('.friends-requests__body').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(12)),
  ),
  css('.friends-requests__rows').styles(display: Display.flex, flexDirection: FlexDirection.column),
  css('.friends-requests__empty, .friends-requests__error').styles(
    border: const Border.symmetric(
      horizontal: BorderSide(color: AppColors.divider, width: Unit.pixels(1)),
    ),
  ),
  css('.friends-requests__empty').styles(
    display: Display.flex,
    padding: const Padding.symmetric(vertical: Unit.pixels(20)),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(4)),
  ),
  css('.friends-requests__empty-title')
      .combine(AppTextStyles.bodyLg)
      .combine(const Styles(fontWeight: FontWeight.w600)),
  css('.friends-requests__empty-text')
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.muted, lineHeight: Unit.pixels(18))),
  css('.friends-requests__error').styles(
    display: Display.flex,
    padding: const Padding.symmetric(vertical: Unit.pixels(16)),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(16)),
  ),
  css('.friends-requests__error > .app-inline-error').styles(
    minWidth: Unit.zero,
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
];
