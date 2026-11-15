import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:skill_battles/core/domain/entity/page_info_entity.dart';
import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/core/domain/usecases/generate_id_usecase.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/presentation/bloc/load_status.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_params_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitations_snapshot_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_list_item_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friends_page_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friends_page_params_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/room_invitations_params_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/send_duel_invitation_params_entity.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_duel_invitation_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friends_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_room_invitations_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/send_duel_invitation_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/watch_duel_invitation_changes_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/withdraw_duel_invitation_usecase.dart';

part 'room_invitation_event.dart';
part 'room_invitation_state.dart';

/// The host's targeted invitation inside one private room: restore, pick an
/// accepted friend, send, withdraw, follow DUEL_INVITATION_CHANGED.
///
/// One Send intent keeps one `requestId` across retries; the intent ends
/// when the server gives a definite answer, so a later send (or another
/// friend) gets a new id. At most one invitation is pending per room; the
/// room itself is owned by `PrivateDuelBloc`.
final class RoomInvitationBloc
    extends Bloc<RoomInvitationEvent, RoomInvitationState> {
  RoomInvitationBloc({
    required this._getRoomInvitations,
    required this._getDuelInvitation,
    required this._sendDuelInvitation,
    required this._withdrawDuelInvitation,
    required this._getFriends,
    required this._watchDuelInvitationChanges,
    required this._watchConnection,
    required this._generateId,
    this.pageSize = 20,
  }) : super(const RoomInvitationState()) {
    on<RoomInvitationStarted>(_onStarted, transformer: restartable());
    on<RoomInvitationRefreshRequested>(_onRefresh, transformer: restartable());
    on<RoomInvitationFriendsRequested>(
      _onFriendsRequested,
      transformer: restartable(),
    );
    on<RoomInvitationFriendsPageRequested>(
      _onFriendsPageRequested,
      transformer: droppable(),
    );
    on<RoomInvitationSendRequested>(_onSend, transformer: concurrent());
    on<RoomInvitationWithdrawRequested>(_onWithdraw, transformer: droppable());
    on<RoomInvitationResultCleared>(_onResultCleared);
    on<_InvitationReceived>(_onInvitationReceived);
    on<_Reconnected>(_onReconnected);
  }

  final GetRoomInvitationsUsecase _getRoomInvitations;
  final GetDuelInvitationUsecase _getDuelInvitation;
  final SendDuelInvitationUsecase _sendDuelInvitation;
  final WithdrawDuelInvitationUsecase _withdrawDuelInvitation;
  final GetFriendsUsecase _getFriends;
  final WatchDuelInvitationChangesUsecase _watchDuelInvitationChanges;
  final WatchConnectionUsecase _watchConnection;
  final GenerateIdUsecase _generateId;
  final int pageSize;

  StreamSubscription<DuelInvitationEntity>? _invitationSubscription;
  StreamSubscription<RealtimeStatus>? _connectionSubscription;
  RealtimeStatus? _connection;
  int _restoreVersion = 0;
  int _friendsVersion = 0;

  // Dismissing a result only clears its UI. Retain its version so a late
  // HTTP replay in the repository stream cannot resolve the next Send.
  final Map<String, int> _invitationVersions = <String, int>{};
  DuelInvitationEntity? _latestInvitation;

  /// The open Send intent: kept after an uncertain failure for a retry.
  _SendIntent? _intent;

  Future<void> _onStarted(
    RoomInvitationStarted event,
    Emitter<RoomInvitationState> emit,
  ) async {
    _invitationSubscription ??= _watchDuelInvitationChanges(const NoParams())
        .listen((DuelInvitationEntity i) => add(_InvitationReceived(i)));
    _connectionSubscription ??= _watchConnection(const NoParams())
        .listen((RealtimeStatus status) {
          final RealtimeStatus? previous = _connection;
          _connection = status;
          if (previous != null &&
              previous != RealtimeStatus.connected &&
              status == RealtimeStatus.connected) {
            add(const _Reconnected());
          }
        });
    if (state.duelId != event.duelId) {
      _intent = null;
      _invitationVersions.clear();
      _latestInvitation = null;
      emit(RoomInvitationState(duelId: event.duelId));
    }
    await _restore(emit);
  }

  Future<void> _onRefresh(
    RoomInvitationRefreshRequested event,
    Emitter<RoomInvitationState> emit,
  ) => _restore(emit);

  void _onReconnected(_Reconnected event, Emitter<RoomInvitationState> emit) {
    if (state.duelId != null) add(const RoomInvitationRefreshRequested());
  }

  /// Rebuilds the room's invitation from the server (rooms and invitations
  /// live in memory there and can vanish on a restart).
  Future<void> _restore(Emitter<RoomInvitationState> emit) async {
    final String? duelId = state.duelId;
    if (duelId == null) return;
    final int version = ++_restoreVersion;
    emit(state.copyWith(restoreStatus: LoadStatus.loading));
    final Either<Failure, DuelInvitationsSnapshotEntity> result =
        await _getRoomInvitations(RoomInvitationsParamsEntity(duelId: duelId));
    if (emit.isDone || version != _restoreVersion || duelId != state.duelId) {
      return;
    }
    final Failure? failure = result.getLeft();
    if (failure != null) {
      emit(
        state.copyWith(
          restoreStatus: LoadStatus.failure,
          restoreFailure: failure,
        ),
      );
      return;
    }
    final DuelInvitationsSnapshotEntity snapshot = result.toNullable()!;
    emit(
      state.copyWith(
        restoreStatus: LoadStatus.success,
        clockOffset: snapshot.clockOffset,
        resetRestoreFailure: true,
      ),
    );
    final DuelInvitationEntity? latest = _latestOf(snapshot.invitations);
    if (latest != null) {
      _apply(latest, emit);
      return;
    }
    // The pending list cannot explain a missing invitation: read it.
    final DuelInvitationEntity? pending = state.pendingInvitation;
    if (pending == null) return;
    final Either<Failure, DuelInvitationEntity> known =
        await _getDuelInvitation(
          DuelInvitationParamsEntity(invitationId: pending.id),
        );
    if (emit.isDone || version != _restoreVersion) return;
    known.match((Failure failure) {
      if (failure.hasCode(ApiErrorCodes.duelInvitationNotFound) &&
          state.invitation?.id == pending.id) {
        emit(state.copyWith(resetInvitation: true));
      }
    }, (DuelInvitationEntity invitation) => _apply(invitation, emit));
  }

  DuelInvitationEntity? _latestOf(List<DuelInvitationEntity> items) {
    DuelInvitationEntity? latest;
    for (final DuelInvitationEntity item in items) {
      if (item.isIncoming) continue;
      if (latest == null ||
          (item.status.isPending && !latest.status.isPending) ||
          (item.status.isPending == latest.status.isPending &&
              item.createdAt.isAfter(latest.createdAt))) {
        latest = item;
      }
    }
    return latest;
  }

  void _onInvitationReceived(
    _InvitationReceived event,
    Emitter<RoomInvitationState> emit,
  ) => _apply(event.invitation, emit);

  /// Keeps the room's newest invitation; a lower version of the same id
  /// never replaces it.
  void _apply(
    DuelInvitationEntity invitation,
    Emitter<RoomInvitationState> emit,
  ) {
    if (invitation.duelId != state.duelId || invitation.isIncoming) return;
    final int? knownVersion = _invitationVersions[invitation.id];
    if (knownVersion != null && invitation.version <= knownVersion) return;
    _invitationVersions[invitation.id] = invitation.version;
    final DuelInvitationEntity? current = _latestInvitation;
    if (current != null &&
        current.id != invitation.id &&
        invitation.createdAt.isBefore(current.createdAt)) {
      return;
    }
    _latestInvitation = invitation;
    // The server knows this friend's invitation: an open intent for them is
    // resolved (an uncertain send did go through), so a later send must
    // get a new request id and no retry is offered.
    final _SendIntent? intent = _intent;
    if (intent != null &&
        intent.duelId == invitation.duelId &&
        intent.friendId == invitation.recipient.id) {
      _intent = null;
      emit(
        state.copyWith(
          invitation: invitation,
          sendStatus: LoadStatus.success,
          canRetrySend: false,
          resetSendFailure: true,
        ),
      );
      return;
    }
    emit(state.copyWith(invitation: invitation));
  }

  // ---------------------------------------------------------------------
  // Friends picker.

  Future<void> _onFriendsRequested(
    RoomInvitationFriendsRequested event,
    Emitter<RoomInvitationState> emit,
  ) async {
    final int version = ++_friendsVersion;
    emit(
      state.copyWith(
        friendsStatus: LoadStatus.loading,
        friendsPageStatus: LoadStatus.initial,
        resetFriendsPageFailure: true,
      ),
    );
    final Either<Failure, FriendsPageEntity> result = await _getFriends(
      FriendsPageParamsEntity(size: pageSize),
    );
    if (emit.isDone || version != _friendsVersion) return;
    result.match(
      (Failure failure) => emit(
        state.copyWith(
          friendsStatus: LoadStatus.failure,
          friendsFailure: failure,
        ),
      ),
      (FriendsPageEntity page) => emit(
        state.copyWith(
          friendsStatus: LoadStatus.success,
          friends: List<FriendListItemEntity>.unmodifiable(page.items),
          friendsPage: page.page,
          resetFriendsFailure: true,
        ),
      ),
    );
  }

  /// Replaces the picker's friends with page [event.page]. Out-of-range
  /// pages are clamped; an empty page past the end (the list shrank) loads
  /// the last existing page. The newest picker load wins.
  Future<void> _onFriendsPageRequested(
    RoomInvitationFriendsPageRequested event,
    Emitter<RoomInvitationState> emit,
  ) async {
    final PageInfoEntity? info = state.friendsPage;
    if (info == null ||
        state.friendsStatus.isLoading ||
        state.friendsPageStatus.isLoading) {
      return;
    }
    int page = event.page < 0 ? 0 : event.page;
    if (info.totalPages > 0 && page >= info.totalPages) {
      page = info.totalPages - 1;
    }
    if (page == info.page) return;
    final int version = ++_friendsVersion;
    emit(
      state.copyWith(
        friendsPageStatus: LoadStatus.loading,
        resetFriendsPageFailure: true,
      ),
    );
    Either<Failure, FriendsPageEntity> result = await _getFriends(
      FriendsPageParamsEntity(page: page, size: pageSize),
    );
    if (emit.isDone || version != _friendsVersion) return;
    final FriendsPageEntity? first = result.toNullable();
    if (first != null &&
        first.items.isEmpty &&
        page > 0 &&
        first.page.totalPages > 0 &&
        page >= first.page.totalPages) {
      result = await _getFriends(
        FriendsPageParamsEntity(
          page: first.page.totalPages - 1,
          size: pageSize,
        ),
      );
      if (emit.isDone || version != _friendsVersion) return;
    }
    result.match(
      (Failure failure) => emit(
        state.copyWith(
          friendsPageStatus: LoadStatus.failure,
          friendsPageFailure: failure,
        ),
      ),
      (FriendsPageEntity loaded) => emit(
        state.copyWith(
          friendsPageStatus: LoadStatus.success,
          friends: List<FriendListItemEntity>.unmodifiable(loaded.items),
          friendsPage: loaded.page,
          resetFriendsPageFailure: true,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Send and withdraw.

  Future<void> _onSend(
    RoomInvitationSendRequested event,
    Emitter<RoomInvitationState> emit,
  ) async {
    final String? duelId = state.duelId;
    if (duelId == null || !state.canInvite) return;
    final _SendIntent intent =
        _intent != null &&
            _intent!.duelId == duelId &&
            _intent!.friendId == event.friendId
        ? _intent!
        : _SendIntent(
            duelId: duelId,
            friendId: event.friendId,
            requestId: _generateId(const NoParams()),
          );
    _intent = intent;
    emit(
      state.copyWith(
        sendStatus: LoadStatus.loading,
        sendFriendId: event.friendId,
        canRetrySend: false,
        resetSendFailure: true,
      ),
    );
    final Either<Failure, DuelInvitationEntity> result =
        await _sendDuelInvitation(
          SendDuelInvitationParamsEntity(
            duelId: intent.duelId,
            friendId: intent.friendId,
            requestId: intent.requestId,
          ),
        );
    // A push or restore can resolve this intent before the HTTP request
    // finishes. Its later answer must not reopen a retry or replace a newer
    // invitation (including when this bloc has switched rooms meanwhile).
    if (emit.isDone || duelId != state.duelId || _intent != intent) return;
    final Failure? failure = result.getLeft();
    if (failure == null) {
      _intent = null;
      final DuelInvitationEntity invitation = result.toNullable()!;
      // The answer to this intent replaces whatever was shown, even a
      // terminal replay of the same request id.
      if (state.invitation?.id != invitation.id) {
        emit(state.copyWith(resetInvitation: true));
      }
      _apply(invitation, emit);
      emit(state.copyWith(sendStatus: LoadStatus.success));
      return;
    }
    final bool retryable =
        _isUncertain(failure) || failure.hasCode(ApiErrorCodes.rateLimited);
    if (!retryable) _intent = null;
    emit(
      state.copyWith(
        sendStatus: LoadStatus.failure,
        sendFailure: failure,
        canRetrySend: retryable,
      ),
    );
    if (failure.hasCode(ApiErrorCodes.duelInvitationAlreadyPending)) {
      await _restore(emit);
    }
  }

  Future<void> _onWithdraw(
    RoomInvitationWithdrawRequested event,
    Emitter<RoomInvitationState> emit,
  ) async {
    final DuelInvitationEntity? pending = state.pendingInvitation;
    if (pending == null) return;
    emit(
      state.copyWith(
        withdrawStatus: LoadStatus.loading,
        resetWithdrawFailure: true,
      ),
    );
    final Either<Failure, Unit> result = await _withdrawDuelInvitation(
      DuelInvitationParamsEntity(invitationId: pending.id),
    );
    if (emit.isDone) return;
    final Failure? failure = result.getLeft();
    if (failure != null &&
        !failure.hasCode(ApiErrorCodes.matchAlreadyFound) &&
        !failure.hasCode(ApiErrorCodes.duelInvitationNotFound)) {
      emit(
        state.copyWith(
          withdrawStatus: LoadStatus.failure,
          withdrawFailure: failure,
        ),
      );
      return;
    }
    // 204 has no body, and MATCH_ALREADY_FOUND means the friend joined:
    // read the authoritative invitation either way.
    final Either<Failure, DuelInvitationEntity> known =
        await _getDuelInvitation(
          DuelInvitationParamsEntity(invitationId: pending.id),
        );
    if (emit.isDone) return;
    known.match((Failure _) {
      // Withdrawn or gone, but unreadable: stop showing it as pending.
      // After MATCH_ALREADY_FOUND keep it until a push or restore says more.
      final bool resolved =
          failure == null ||
          failure.hasCode(ApiErrorCodes.duelInvitationNotFound);
      if (resolved && state.invitation?.id == pending.id) {
        emit(state.copyWith(resetInvitation: true));
      }
    }, (DuelInvitationEntity invitation) => _apply(invitation, emit));
    emit(
      state.copyWith(
        withdrawStatus: failure == null
            ? LoadStatus.success
            : LoadStatus.initial,
      ),
    );
  }

  void _onResultCleared(
    RoomInvitationResultCleared event,
    Emitter<RoomInvitationState> emit,
  ) {
    if (state.pendingInvitation != null || state.sendStatus.isLoading) return;
    emit(
      state.copyWith(
        sendStatus: LoadStatus.initial,
        withdrawStatus: LoadStatus.initial,
        canRetrySend: false,
        resetInvitation: true,
        resetSendFailure: true,
        resetWithdrawFailure: true,
      ),
    );
  }

  static bool _isUncertain(Failure failure) => switch (failure) {
    ConnectionFailure() || TimeoutFailure() => true,
    ApiFailure(:final int statusCode) => statusCode >= 500,
    ParsingFailure() || UnexpectedFailure() => true,
    ValidationFailure() || StorageFailure() => false,
  };

  @override
  Future<void> close() async {
    await _invitationSubscription?.cancel();
    await _connectionSubscription?.cancel();
    return super.close();
  }
}

/// duelId + friendId + requestId of one Send intent.
final class _SendIntent {
  const _SendIntent({
    required this.duelId,
    required this.friendId,
    required this.requestId,
  });

  final String duelId;
  final String friendId;
  final String requestId;
}
