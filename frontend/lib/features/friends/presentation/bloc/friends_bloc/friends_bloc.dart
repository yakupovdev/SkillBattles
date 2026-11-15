import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:skill_battles/core/domain/entity/page_info_entity.dart';
import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/presentation/bloc/load_status.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_code_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_list_item_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_params_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_request_direction.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_request_params_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_requests_page_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_requests_params_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friends_page_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friends_page_params_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_status.dart';
import 'package:skill_battles/features/friends/domain/entity/send_friend_request_params_entity.dart';
import 'package:skill_battles/features/friends/domain/usecases/accept_friend_request_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/cancel_friend_request_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/decline_friend_request_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friend_code_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friend_requests_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friends_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/remove_friend_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/send_friend_request_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/watch_friendship_changes_usecase.dart';

part 'friends_event.dart';
part 'friends_state.dart';

typedef _SliceUpdate = FriendsListSlice<T> Function<T extends Object>(
  FriendsListSlice<T> slice,
);

/// The Friends screen: own code, the paged friends list, paged incoming and
/// outgoing requests, add by code and the per-row commands.
///
/// Lists are paged (one page shown at a time) and never patched locally: a
/// relevant FRIENDSHIP_CHANGED, an own command result or a reconnect marks
/// lists dirty and their CURRENT page is read again (invalidations are
/// coalesced; a page now past the end falls back to the last page). Each
/// list has a version, so only the newest load of a list lands.
final class FriendsBloc extends Bloc<FriendsEvent, FriendsState> {
  FriendsBloc({
    required this._getFriendCode,
    required this._getFriends,
    required this._getFriendRequests,
    required this._sendFriendRequest,
    required this._acceptFriendRequest,
    required this._declineFriendRequest,
    required this._cancelFriendRequest,
    required this._removeFriend,
    required this._watchFriendshipChanges,
    required this._watchConnection,
    this.pageSize = 20,
  }) : super(const FriendsState()) {
    on<FriendsStarted>(_onStarted, transformer: droppable());
    on<FriendsRefreshRequested>(_onRefresh, transformer: restartable());
    on<FriendsListRetryRequested>(_onListRetry);
    on<FriendsPageRequested>(_onPageRequested);
    on<FriendRequestSubmitted>(_onSubmitted, transformer: droppable());
    on<FriendRequestAcceptRequested>(_onAccept);
    on<FriendRequestDeclineRequested>(_onDecline);
    on<FriendRequestCancelRequested>(_onCancel);
    on<FriendRemoveRequested>(_onRemove);
    on<_FriendshipChanged>(_onFriendshipChanged);
    on<_Reconnected>(_onReconnected);
    on<_InvalidatedListsFlushed>(_onFlush, transformer: droppable());
  }

  final GetFriendCodeUsecase _getFriendCode;
  final GetFriendsUsecase _getFriends;
  final GetFriendRequestsUsecase _getFriendRequests;
  final SendFriendRequestUsecase _sendFriendRequest;
  final AcceptFriendRequestUsecase _acceptFriendRequest;
  final DeclineFriendRequestUsecase _declineFriendRequest;
  final CancelFriendRequestUsecase _cancelFriendRequest;
  final RemoveFriendUsecase _removeFriend;
  final WatchFriendshipChangesUsecase _watchFriendshipChanges;
  final WatchConnectionUsecase _watchConnection;
  final int pageSize;

  StreamSubscription<RelationshipEntity>? _changesSubscription;
  StreamSubscription<RealtimeStatus>? _connectionSubscription;
  RealtimeStatus? _connection;

  final Map<FriendsList, int> _versions = <FriendsList, int>{
    for (final FriendsList list in FriendsList.values) list: 0,
  };
  final Set<FriendsList> _dirty = <FriendsList>{};

  /// Page each list shows or is moving to; invalidations re-read it.
  final Map<FriendsList, int> _targetPages = <FriendsList, int>{};

  Future<void> _onStarted(
    FriendsStarted event,
    Emitter<FriendsState> emit,
  ) async {
    _changesSubscription ??= _watchFriendshipChanges(const NoParams()).listen(
      (RelationshipEntity relationship) =>
          add(_FriendshipChanged(relationship)),
    );
    _connectionSubscription ??= _watchConnection(const NoParams())
        .listen((RealtimeStatus status) {
          final RealtimeStatus? previous = _connection;
          _connection = status;
          // The first value is the current status, not a reconnect.
          if (previous != null &&
              previous != RealtimeStatus.connected &&
              status == RealtimeStatus.connected) {
            add(const _Reconnected());
          }
        });
    await Future.wait<void>(<Future<void>>[
      _loadCode(emit),
      for (final FriendsList list in FriendsList.values)
        _loadPage(list, 0, emit),
    ]);
  }

  Future<void> _onRefresh(
    FriendsRefreshRequested event,
    Emitter<FriendsState> emit,
  ) async {
    await Future.wait<void>(<Future<void>>[
      if (!state.codeStatus.isSuccess) _loadCode(emit),
      for (final FriendsList list in FriendsList.values)
        _loadCurrent(list, emit),
    ]);
  }

  Future<void> _onListRetry(
    FriendsListRetryRequested event,
    Emitter<FriendsState> emit,
  ) => _loadCurrent(event.list, emit);

  void _onReconnected(_Reconnected event, Emitter<FriendsState> emit) =>
      _invalidate(FriendsList.values);

  Future<void> _loadCode(Emitter<FriendsState> emit) async {
    emit(state.copyWith(codeStatus: LoadStatus.loading));
    final Either<Failure, FriendCodeEntity> result = await _getFriendCode(
      const NoParams(),
    );
    if (emit.isDone) return;
    result.match(
      (Failure failure) => emit(
        state.copyWith(codeStatus: LoadStatus.failure, codeFailure: failure),
      ),
      (FriendCodeEntity code) => emit(
        state.copyWith(
          codeStatus: LoadStatus.success,
          code: code,
          resetCodeFailure: true,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Paging.

  /// Reads page [page] of [list] (the shown or requested one) and replaces
  /// the items. A page past the end loads the last existing page instead
  /// (e.g. the only row of the last page was removed). Items stay visible
  /// while it loads and on failure. [isPageChange] reports through
  /// `pageStatus`, anything else through `loadStatus`; the newest load of a
  /// list wins.
  Future<void> _loadPage(
    FriendsList list,
    int page,
    Emitter<FriendsState> emit, {
    bool isPageChange = false,
  }) async {
    final int version = _versions[list]! + 1;
    _versions[list] = version;
    _targetPages[list] = page;
    emit(
      _mapSlice(
        list,
        <T extends Object>(FriendsListSlice<T> slice) => isPageChange
            ? slice.copyWith(
                pageStatus: LoadStatus.loading,
                resetPageFailure: true,
              )
            : slice.copyWith(
                loadStatus: LoadStatus.loading,
                // A refresh supersedes a running page change.
                pageStatus: LoadStatus.initial,
                resetPageFailure: true,
              ),
      ),
    );
    Either<Failure, _Page> result = await _fetch(list, page);
    if (emit.isDone || version != _versions[list]) return;
    final _Page? first = result.toNullable();
    if (first != null &&
        first.items.isEmpty &&
        page > 0 &&
        first.info.totalPages > 0 &&
        page >= first.info.totalPages) {
      final int last = first.info.totalPages - 1;
      _targetPages[list] = last;
      result = await _fetch(list, last);
      if (emit.isDone || version != _versions[list]) return;
    }
    result.match(
      (Failure failure) => emit(
        _mapSlice(
          list,
          <T extends Object>(FriendsListSlice<T> slice) => isPageChange
              ? slice.copyWith(
                  pageStatus: LoadStatus.failure,
                  pageFailure: failure,
                )
              : slice.copyWith(
                  loadStatus: LoadStatus.failure,
                  failure: failure,
                ),
        ),
      ),
      (_Page loaded) {
        // The page actually shown, so later refetches stay on it.
        _targetPages[list] = loaded.info.page;
        emit(
          _mapSlice(list, <T extends Object>(FriendsListSlice<T> slice) {
            final FriendsListSlice<T> next = slice.copyWith(
              items: List<T>.unmodifiable(loaded.items.cast<T>()),
              page: loaded.info,
            );
            return isPageChange
                ? next.copyWith(
                    pageStatus: LoadStatus.success,
                    resetPageFailure: true,
                  )
                : next.copyWith(
                    loadStatus: LoadStatus.success,
                    resetFailure: true,
                  );
          }),
        );
        _pruneActions(emit);
      },
    );
  }

  /// Re-reads the page [list] shows (or is moving to).
  Future<void> _loadCurrent(FriendsList list, Emitter<FriendsState> emit) =>
      _loadPage(list, _targetPages[list] ?? 0, emit);

  Future<void> _onPageRequested(
    FriendsPageRequested event,
    Emitter<FriendsState> emit,
  ) async {
    final FriendsList list = event.list;
    final FriendsListSlice<Object> slice = state.slice(list);
    if (slice.loadStatus.isLoading || slice.pageStatus.isLoading) return;
    final int totalPages = slice.page?.totalPages ?? 0;
    // Out of range: clamped to the known pages (the server answers an
    // empty page past the end, handled in [_loadPage] too).
    int page = event.page < 0 ? 0 : event.page;
    if (totalPages > 0 && page >= totalPages) page = totalPages - 1;
    if (page == slice.page?.page && slice.loadStatus.isSuccess) return;
    await _loadPage(list, page, emit, isPageChange: true);
  }

  Future<Either<Failure, _Page>> _fetch(FriendsList list, int page) async {
    switch (list) {
      case FriendsList.friends:
        final Either<Failure, FriendsPageEntity> result = await _getFriends(
          FriendsPageParamsEntity(page: page, size: pageSize),
        );
        return result.map(
          (FriendsPageEntity value) => _Page(value.items, value.page),
        );
      case FriendsList.incoming:
      case FriendsList.outgoing:
        final Either<Failure, FriendRequestsPageEntity> result =
            await _getFriendRequests(
              FriendRequestsParamsEntity(
                direction: list == FriendsList.incoming
                    ? FriendRequestDirection.incoming
                    : FriendRequestDirection.outgoing,
                page: page,
                size: pageSize,
              ),
            );
        return result.map(
          (FriendRequestsPageEntity value) => _Page(value.items, value.page),
        );
    }
  }

  FriendsState _mapSlice(FriendsList list, _SliceUpdate update) =>
      switch (list) {
        FriendsList.friends => state.copyWith(
          friends: update<FriendListItemEntity>(state.friends),
        ),
        FriendsList.incoming => state.copyWith(
          incoming: update<RelationshipEntity>(state.incoming),
        ),
        FriendsList.outgoing => state.copyWith(
          outgoing: update<RelationshipEntity>(state.outgoing),
        ),
      };

  // ---------------------------------------------------------------------
  // Invalidation.

  void _onFriendshipChanged(
    _FriendshipChanged event,
    Emitter<FriendsState> emit,
  ) {
    final RelationshipEntity record = event.relationship;
    final FriendsList side = record.isIncoming
        ? FriendsList.incoming
        : FriendsList.outgoing;
    _invalidate(switch (record.status) {
      RelationshipStatus.pending ||
      RelationshipStatus.declined ||
      RelationshipStatus.cancelled => <FriendsList>[side],
      RelationshipStatus.accepted => FriendsList.values,
      RelationshipStatus.removed => <FriendsList>[FriendsList.friends],
    });
  }

  void _invalidate(Iterable<FriendsList> lists) {
    _dirty.addAll(lists);
    add(const _InvalidatedListsFlushed());
  }

  /// Reads the current page of every dirty list once; lists marked while it
  /// runs are read in the next round of the same handler.
  Future<void> _onFlush(
    _InvalidatedListsFlushed event,
    Emitter<FriendsState> emit,
  ) async {
    while (_dirty.isNotEmpty && !emit.isDone) {
      final List<FriendsList> lists = _dirty.toList(growable: false);
      _dirty.clear();
      await Future.wait<void>(
        lists.map((FriendsList list) => _loadCurrent(list, emit)),
      );
    }
  }

  /// Actions of rows that left their lists.
  void _pruneActions(Emitter<FriendsState> emit) {
    final Set<String> requestIds = <String>{
      ...state.incoming.items.map((RelationshipEntity r) => r.id),
      ...state.outgoing.items.map((RelationshipEntity r) => r.id),
    };
    final Set<String> friendIds = state.friends.items
        .map((FriendListItemEntity f) => f.friend.id)
        .toSet();
    final Map<String, FriendsItemAction> requests =
        Map<String, FriendsItemAction>.of(state.requestActions)..removeWhere(
          (String id, FriendsItemAction action) =>
              !requestIds.contains(id) && !action.status.isLoading,
        );
    final Map<String, FriendsItemAction> friends =
        Map<String, FriendsItemAction>.of(state.friendActions)..removeWhere(
          (String id, FriendsItemAction action) =>
              !friendIds.contains(id) && !action.status.isLoading,
        );
    if (requests.length == state.requestActions.length &&
        friends.length == state.friendActions.length) {
      return;
    }
    emit(
      state.copyWith(
        requestActions: Map<String, FriendsItemAction>.unmodifiable(requests),
        friendActions: Map<String, FriendsItemAction>.unmodifiable(friends),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Commands.

  Future<void> _onSubmitted(
    FriendRequestSubmitted event,
    Emitter<FriendsState> emit,
  ) async {
    emit(
      state.copyWith(
        sendStatus: LoadStatus.loading,
        resetSendFailure: true,
        resetSentRequest: true,
      ),
    );
    final Either<Failure, RelationshipEntity> result = await _sendFriendRequest(
      event.params,
    );
    if (emit.isDone) return;
    result.match(
      (Failure failure) {
        emit(
          state.copyWith(sendStatus: LoadStatus.failure, sendFailure: failure),
        );
        // Show the authoritative lists the error refers to; never accept
        // a crossed request automatically.
        if (failure.hasCode(ApiErrorCodes.friendRequestAlreadyReceived)) {
          _invalidate(<FriendsList>[FriendsList.incoming]);
        } else if (failure.hasCode(ApiErrorCodes.friendAlreadyExists)) {
          _invalidate(<FriendsList>[FriendsList.friends]);
        }
      },
      (RelationshipEntity relationship) {
        // 201 (new) and 200 (own pending already existed) look the same.
        emit(
          state.copyWith(
            sendStatus: LoadStatus.success,
            sentRequest: relationship,
          ),
        );
        _invalidate(<FriendsList>[FriendsList.outgoing]);
      },
    );
  }

  Future<void> _onAccept(
    FriendRequestAcceptRequested event,
    Emitter<FriendsState> emit,
  ) => _runRequestCommand(
    event.requestId,
    () => _acceptFriendRequest(
      FriendRequestParamsEntity(requestId: event.requestId),
    ),
    <FriendsList>[FriendsList.incoming, FriendsList.friends],
    emit,
  );

  Future<void> _onDecline(
    FriendRequestDeclineRequested event,
    Emitter<FriendsState> emit,
  ) => _runRequestCommand(
    event.requestId,
    () => _declineFriendRequest(
      FriendRequestParamsEntity(requestId: event.requestId),
    ),
    <FriendsList>[FriendsList.incoming],
    emit,
  );

  Future<void> _onCancel(
    FriendRequestCancelRequested event,
    Emitter<FriendsState> emit,
  ) => _runRequestCommand(
    event.requestId,
    () => _cancelFriendRequest(
      FriendRequestParamsEntity(requestId: event.requestId),
    ),
    <FriendsList>[FriendsList.outgoing],
    emit,
  );

  Future<void> _runRequestCommand<T>(
    String requestId,
    Future<Either<Failure, T>> Function() command,
    List<FriendsList> affected,
    Emitter<FriendsState> emit,
  ) async {
    if (state.requestActions[requestId]?.status.isLoading ?? false) return;
    _setRequestAction(
      requestId,
      const FriendsItemAction(status: LoadStatus.loading),
      emit,
    );
    final Either<Failure, T> result = await command();
    if (emit.isDone) return;
    final Failure? failure = result.getLeft();
    _setRequestAction(
      requestId,
      failure == null
          ? const FriendsItemAction(status: LoadStatus.success)
          : FriendsItemAction(status: LoadStatus.failure, failure: failure),
      emit,
    );
    // A success or an already-resolved request changes the lists; an
    // uncertain failure may have too. Refetch rather than guess.
    _invalidate(affected);
  }

  Future<void> _onRemove(
    FriendRemoveRequested event,
    Emitter<FriendsState> emit,
  ) async {
    final String friendId = event.friendId;
    if (state.friendActions[friendId]?.status.isLoading ?? false) return;
    _setFriendAction(
      friendId,
      const FriendsItemAction(status: LoadStatus.loading),
      emit,
    );
    final Either<Failure, Unit> result = await _removeFriend(
      FriendParamsEntity(friendId: friendId),
    );
    if (emit.isDone) return;
    final Failure? failure = result.getLeft();
    _setFriendAction(
      friendId,
      failure == null
          ? const FriendsItemAction(status: LoadStatus.success)
          : FriendsItemAction(status: LoadStatus.failure, failure: failure),
      emit,
    );
    _invalidate(<FriendsList>[FriendsList.friends]);
  }

  void _setRequestAction(
    String requestId,
    FriendsItemAction action,
    Emitter<FriendsState> emit,
  ) => emit(
    state.copyWith(
      requestActions: Map<String, FriendsItemAction>.unmodifiable(
        <String, FriendsItemAction>{...state.requestActions, requestId: action},
      ),
    ),
  );

  void _setFriendAction(
    String friendId,
    FriendsItemAction action,
    Emitter<FriendsState> emit,
  ) => emit(
    state.copyWith(
      friendActions: Map<String, FriendsItemAction>.unmodifiable(
        <String, FriendsItemAction>{...state.friendActions, friendId: action},
      ),
    ),
  );

  @override
  Future<void> close() async {
    await _changesSubscription?.cancel();
    await _connectionSubscription?.cancel();
    return super.close();
  }
}

/// One fetched page of any list.
final class _Page {
  const _Page(this.items, this.info);

  final List<Object> items;
  final PageInfoEntity info;
}
