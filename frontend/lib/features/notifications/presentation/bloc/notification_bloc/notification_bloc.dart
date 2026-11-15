import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:skill_battles/core/domain/entity/battle_result_entity.dart';
import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/account/domain/entity/activity_entity.dart';
import 'package:skill_battles/features/account/domain/usecases/get_activity_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/watch_signed_in_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/entity/rematch_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/rematch_status.dart';
import 'package:skill_battles/features/battle_result/domain/entity/result_params_entity.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/cancel_rematch_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/get_rematch_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/get_result_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/request_rematch_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/watch_rematches_usecase.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_params_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_reason.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_status.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitations_snapshot_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_request_params_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_requests_page_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_requests_params_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_status.dart';
import 'package:skill_battles/features/friends/domain/entity/room_invitations_params_entity.dart';
import 'package:skill_battles/features/friends/domain/usecases/accept_duel_invitation_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/accept_friend_request_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/decline_duel_invitation_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/decline_friend_request_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_duel_invitation_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friend_request_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friend_requests_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_incoming_duel_invitations_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_room_invitations_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/watch_duel_invitation_changes_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/watch_friendship_changes_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/watch_signed_in_user_usecase.dart';

part 'notification_event.dart';
part 'notification_state.dart';

/// App-scope in-app notifications of the signed-in user for the global
/// overlay. Rematch is the first kind; a new kind adds a
/// [NotificationPayload] subclass, its stream and its Accept/Decline
/// handlers (the dispatch switches are exhaustive over the payload).
///
/// Generic rules (every kind):
/// - Everything is ingested whatever the current route; hiding a card on
///   the route that already shows it inline is a render-time filter.
/// - Deadlines are client-driven from [NotificationItem.expiresAt]: a
///   visible prompt turns expired and is removed [expiredLinger] later
///   without a notice; a hidden prompt or an own request is removed with an
///   `expired` notice.
/// - A matched battle is exposed through [NotificationState.battleToOpen]
///   at most once per battle id in a session.
/// - Sign-out clears everything and cancels timers; answers of the previous
///   session are dropped. Nothing is emitted after close.
///
/// Rematch rules:
/// - Versions are kept per source battle also after removal, so a late
///   lower version never reopens an item.
/// - The source battle is loaded once per id for the opponent, the
///   discipline and the own user id (`BattleResultEntity.myUserId`). Until
///   the own id is known, a waiting rematch is held back; if the load fails
///   while the id is still unknown, the rematch is shown as incoming, so a
///   request is never lost.
/// - After a reconnect every known waiting rematch is re-read. There is no
///   REST list, so a request made while offline is not recovered.
///
/// Friends kinds (friend requests, room invitations):
/// - Recovery runs on start, sign-in, account switch and every reconnect:
///   incoming PENDING requests (first page of 20), incoming invitations,
///   own activity, and the host's own invitation (activity PRIVATE_DUEL →
///   its room's invitations; a known one whose room is no longer the own
///   activity → re-read by id). Pushes that arrive meanwhile are buffered
///   and applied after the snapshot, in one synchronous step. A recovery
///   token drops superseded answers; the session token drops old accounts.
///   Startup and reconnect recoveries show every recovered prompt again.
/// - Versions per (kind, resource id); terminal records leave a tombstone
///   keyed by the resource id, so a late PENDING never reopens it while a
///   new relationship id after re-adding shows again.
/// - An uncertain Accept re-reads the resource and own activity before
///   deciding; it never assumes success. Own BATTLE activity resolves a
///   lost acceptance.
/// - The battle of an own accept, and of the host's own invitation being
///   accepted, goes through [NotificationState.battleToOpen] once per id.
/// - The host's own invitation is re-read by id when an activity read
///   shows its room is no longer the own activity, so a lost ACCEPTED push
///   still reaches the host on the next route change or reconnect.
final class NotificationBloc
    extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc({
    required this._watchRematches,
    required this._getRematch,
    required this._getResult,
    required this._requestRematch,
    required this._cancelRematch,
    required this._getActivity,
    required this._watchSignedIn,
    required this._watchConnection,
    required this._isSignedIn,
    required this._watchSignedInUser,
    required this._watchFriendshipChanges,
    required this._watchDuelInvitationChanges,
    required this._getFriendRequests,
    required this._getFriendRequest,
    required this._acceptFriendRequest,
    required this._declineFriendRequest,
    required this._getIncomingDuelInvitations,
    required this._getRoomInvitations,
    required this._getDuelInvitation,
    required this._acceptDuelInvitation,
    required this._declineDuelInvitation,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const NotificationState()) {
    on<NotificationStarted>(_onStarted);
    on<NotificationAcceptRequested>(_onAcceptRequested);
    on<NotificationDeclineRequested>(_onDeclineRequested);
    on<NotificationHidden>(_onHidden);
    on<NotificationHiddenShown>(_onHiddenShown);
    on<NotificationActivityRefreshRequested>(
      _onActivityRefreshRequested,
      transformer: restartable(),
    );
    on<NotificationBattleOpened>(_onBattleOpened);
    on<NotificationNoticeShown>(_onNoticeShown);
    on<_SignedInChanged>(_onSignedInChanged);
    on<_ConnectionChanged>(_onConnectionChanged);
    on<_DeadlineReached>(_onDeadlineReached);
    on<_ExpiredLingerElapsed>(_onExpiredLingerElapsed);
    on<_RematchReceived>(_onRematchReceived);
    on<_RematchRecoveryRequested>(
      _onRematchRecoveryRequested,
      transformer: restartable(),
    );
    on<_RematchEnrichmentRequested>(_onRematchEnrichmentRequested);
    on<_SignedInUserChanged>(_onSignedInUserChanged);
    on<_FriendsRecoveryRequested>(
      _onFriendsRecoveryRequested,
      transformer: restartable(),
    );
    on<_FriendshipReceived>(_onFriendshipReceived);
    on<_DuelInvitationReceived>(_onDuelInvitationReceived);
    on<_OutgoingInvitationCheckRequested>(
      _onOutgoingInvitationCheckRequested,
      transformer: droppable(),
    );
  }

  final WatchRematchesUsecase _watchRematches;
  final GetRematchUsecase _getRematch;
  final GetResultUsecase _getResult;
  final RequestRematchUsecase _requestRematch;
  final CancelRematchUsecase _cancelRematch;
  final GetActivityUsecase _getActivity;
  final WatchSignedInUsecase _watchSignedIn;
  final WatchConnectionUsecase _watchConnection;
  final WatchSignedInUserUsecase _watchSignedInUser;
  final WatchFriendshipChangesUsecase _watchFriendshipChanges;
  final WatchDuelInvitationChangesUsecase _watchDuelInvitationChanges;
  final GetFriendRequestsUsecase _getFriendRequests;
  final GetFriendRequestUsecase _getFriendRequest;
  final AcceptFriendRequestUsecase _acceptFriendRequest;
  final DeclineFriendRequestUsecase _declineFriendRequest;
  final GetIncomingDuelInvitationsUsecase _getIncomingDuelInvitations;
  final GetRoomInvitationsUsecase _getRoomInvitations;
  final GetDuelInvitationUsecase _getDuelInvitation;
  final AcceptDuelInvitationUsecase _acceptDuelInvitation;
  final DeclineDuelInvitationUsecase _declineDuelInvitation;
  final DateTime Function() _now;

  /// Incoming friend requests recovered at once (approved page size).
  static const int friendRequestsPageSize = 20;

  /// How long an expired visible card stays before it is removed.
  static const Duration expiredLinger = Duration(seconds: 4);

  final List<StreamSubscription<Object?>> _subscriptions =
      <StreamSubscription<Object?>>[];
  bool _isSignedIn;

  /// Bumped on every sign-in change; answers of an older session are
  /// dropped.
  int _session = 0;

  /// Never reset, so notice ids stay unique for the whole app session.
  int _noticeSequence = 0;
  RealtimeStatus? _lastStatus;
  final Map<String, Timer> _deadlines = <String, Timer>{};
  final Map<String, Timer> _lingers = <String, Timer>{};
  final Set<String> _openedBattles = <String>{};

  // Rematch kind, keyed by source battle id.
  String? _myUserId;
  final Map<String, int> _rematchVersions = <String, int>{};
  final Map<String, RematchEntity> _unclassifiedRematches =
      <String, RematchEntity>{};
  final Set<String> _enrichmentStarted = <String>{};
  final Set<String> _enrichmentDone = <String>{};
  final Map<String, ({String? nickname, String disciplineCode})>
  _rematchDetails = <String, ({String? nickname, String disciplineCode})>{};

  /// Own Declines (in flight or done): their CANCELLED gives no notice.
  final Set<String> _ownDeclines = <String>{};

  /// Latest activity read; older answers are dropped.
  int _activityRun = 0;

  // Friends kinds, keyed by relationship id / invitation id.
  String? _userId;
  int _friendsRecovery = 0;
  bool _friendsRecovering = false;
  bool _reshowPending = false;
  final List<Object> _friendsBuffer = <Object>[];
  final Map<String, int> _requestVersions = <String, int>{};
  final Map<String, int> _requestTombstones = <String, int>{};
  final Map<String, int> _invitationVersions = <String, int>{};
  final Map<String, int> _invitationTombstones = <String, int>{};

  /// Invitations whose Accept this player started and that are not settled:
  /// an ACCEPTED push for one of them opens the battle even when the HTTP
  /// answer is lost.
  final Set<String> _acceptingInvitations = <String>{};
  final Set<String> _noticedRelationships = <String>{};
  final Set<String> _noticedInvitations = <String>{};

  /// Server minus local time of the latest invitation snapshot.
  Duration _clockOffset = Duration.zero;

  // ---------------------------------------------------------------------
  // Session, connection, activity.

  void _onStarted(NotificationStarted event, Emitter<NotificationState> emit) {
    if (_subscriptions.isNotEmpty) return;
    _subscriptions
      ..add(
        _watchSignedIn(const NoParams())
            .listen((bool signedIn) => add(_SignedInChanged(signedIn))),
      )
      ..add(
        _watchConnection(const NoParams())
            .listen((RealtimeStatus status) => add(_ConnectionChanged(status))),
      )
      ..add(
        _watchRematches(const NoParams())
            .listen((RematchEntity rematch) => add(_RematchReceived(rematch))),
      )
      ..add(
        _watchSignedInUser(const NoParams())
            .listen((String? id) => add(_SignedInUserChanged(id))),
      )
      ..add(
        _watchFriendshipChanges(const NoParams()).listen(
          (RelationshipEntity relationship) =>
              add(_FriendshipReceived(relationship)),
        ),
      )
      ..add(
        _watchDuelInvitationChanges(const NoParams()).listen(
          (DuelInvitationEntity invitation) =>
              add(_DuelInvitationReceived(invitation)),
        ),
      );
    // The recovery also reads own activity (the busy flag).
    if (_isSignedIn) add(const _FriendsRecoveryRequested(baseline: true));
  }

  void _onSignedInChanged(
    _SignedInChanged event,
    Emitter<NotificationState> emit,
  ) {
    // Token refreshes repeat `true`: nothing changes.
    if (event.isSignedIn == _isSignedIn) return;
    _isSignedIn = event.isSignedIn;
    _clearSession();
    emit(NotificationState(isConnected: state.isConnected));
    if (_isSignedIn) add(const _FriendsRecoveryRequested(baseline: true));
  }

  void _onConnectionChanged(
    _ConnectionChanged event,
    Emitter<NotificationState> emit,
  ) {
    final RealtimeStatus? previous = _lastStatus;
    _lastStatus = event.status;
    final bool isConnected = event.status == RealtimeStatus.connected;
    if (isConnected != state.isConnected) {
      emit(state.copyWith(isConnected: isConnected));
    }
    if (isConnected &&
        previous != null &&
        previous != RealtimeStatus.connected) {
      add(const _RematchRecoveryRequested());
      add(const _FriendsRecoveryRequested(baseline: true));
    }
  }

  Future<void> _onActivityRefreshRequested(
    NotificationActivityRefreshRequested event,
    Emitter<NotificationState> emit,
  ) async {
    if (!_isSignedIn) return;
    final int session = _session;
    final int run = ++_activityRun;
    final Either<Failure, ActivityEntity> result = await _getActivity(
      const NoParams(),
    );
    if (emit.isDone || session != _session || run != _activityRun) return;
    // A failed read keeps the last known value.
    result.match((_) {}, (ActivityEntity activity) {
      emit(state.copyWith(isBusy: !activity.isNone));
      _checkOutgoingInvitation(activity);
    });
  }

  // ---------------------------------------------------------------------
  // Card actions (generic, dispatched by kind).

  Future<void> _onAcceptRequested(
    NotificationAcceptRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final NotificationItem? item = _actionable(event.id);
    if (item == null) return;
    switch (item.payload) {
      case RematchNotificationPayload():
        await _acceptRematch(item, emit);
      case FriendRequestNotificationPayload():
        await _respondToRequest(item, accept: true, emit: emit);
      case DuelInvitationNotificationPayload():
        await _acceptInvitation(item, emit);
    }
  }

  Future<void> _onDeclineRequested(
    NotificationDeclineRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final NotificationItem? item = _actionable(event.id);
    if (item == null) return;
    switch (item.payload) {
      case RematchNotificationPayload():
        await _declineRematch(item, emit);
      case FriendRequestNotificationPayload():
        await _respondToRequest(item, accept: false, emit: emit);
      case DuelInvitationNotificationPayload():
        await _declineInvitation(item, emit);
    }
  }

  void _onHidden(NotificationHidden event, Emitter<NotificationState> emit) {
    final NotificationItem? item = state.item(event.id);
    if (item == null || !item.isPrompt) return;
    if (item.isExpired) {
      _removeItem(item.id, emit);
      return;
    }
    if (!item.isHidden) _putItem(item.copyWith(isHidden: true), emit);
  }

  void _onHiddenShown(
    NotificationHiddenShown event,
    Emitter<NotificationState> emit,
  ) {
    if (!state.items.any(_isHiddenPending)) return;
    emit(
      state.copyWith(
        items: List<NotificationItem>.unmodifiable(<NotificationItem>[
          for (final NotificationItem item in state.items)
            _isHiddenPending(item) ? item.copyWith(isHidden: false) : item,
        ]),
      ),
    );
  }

  static bool _isHiddenPending(NotificationItem item) =>
      item.isPrompt && item.isHidden && !item.isExpired;

  void _onBattleOpened(
    NotificationBattleOpened event,
    Emitter<NotificationState> emit,
  ) {
    // Also sent by screens that navigate themselves (the private room on
    // MATCHED): the id never becomes `battleToOpen` afterwards.
    _openedBattles.add(event.battleId);
    if (state.battleToOpen != event.battleId) return;
    emit(state.copyWith(resetBattleToOpen: true));
  }

  void _onNoticeShown(
    NotificationNoticeShown event,
    Emitter<NotificationState> emit,
  ) {
    if (!state.notices.any((NotificationNotice n) => n.id == event.noticeId)) {
      return;
    }
    emit(
      state.copyWith(
        notices: List<NotificationNotice>.unmodifiable(
          state.notices.where((NotificationNotice n) => n.id != event.noticeId),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Deadlines (generic).

  void _onDeadlineReached(
    _DeadlineReached event,
    Emitter<NotificationState> emit,
  ) {
    _deadlines.remove(event.itemId);
    _expire(event.itemId, emit);
  }

  void _onExpiredLingerElapsed(
    _ExpiredLingerElapsed event,
    Emitter<NotificationState> emit,
  ) {
    _lingers.remove(event.itemId);
    final NotificationItem? item = state.item(event.itemId);
    if (item != null && item.isExpired) _removeItem(item.id, emit);
  }

  /// Local deadline, server EXPIRED and a REMATCH_EXPIRED answer all end
  /// here.
  void _expire(String itemId, Emitter<NotificationState> emit) {
    final NotificationItem? item = state.item(itemId);
    if (item == null || item.isExpired) return;
    _deadlines.remove(itemId)?.cancel();
    if (item.isPrompt && !item.isHidden) {
      _putItem(item.copyWith(isExpired: true), emit);
      _linger(itemId);
      return;
    }
    if (item.kind == NotificationKind.duelInvitation) {
      // A later server EXPIRED must not repeat the toast.
      _noticedInvitations.add('${item.resourceId}:expired');
    }
    _removeItem(itemId, emit, notice: NotificationNoticeType.expired);
  }

  /// Removes the (closed) card [expiredLinger] from now.
  void _linger(String itemId) {
    _lingers.remove(itemId)?.cancel();
    _lingers[itemId] = Timer(expiredLinger, () {
      if (!isClosed) add(_ExpiredLingerElapsed(itemId));
    });
  }

  void _scheduleDeadline(NotificationItem item) {
    _deadlines.remove(item.id)?.cancel();
    final Duration wait = item.expiresAt.difference(_now());
    final String itemId = item.id;
    _deadlines[itemId] = Timer(wait.isNegative ? Duration.zero : wait, () {
      if (!isClosed) add(_DeadlineReached(itemId));
    });
  }

  // ---------------------------------------------------------------------
  // Rematch kind.

  void _onRematchReceived(
    _RematchReceived event,
    Emitter<NotificationState> emit,
  ) => _ingestRematch(event.rematch, emit);

  /// Version guard, then the status rules. A live item accepts an equal
  /// version (re-applying is idempotent); a removed one needs a higher one.
  void _ingestRematch(RematchEntity rematch, Emitter<NotificationState> emit) {
    if (!_isSignedIn) return;
    final String sourceId = rematch.sourceBattleId;
    final int? seen = _rematchVersions[sourceId];
    final bool isLive =
        state.item(_rematchItemId(sourceId)) != null ||
        _unclassifiedRematches.containsKey(sourceId);
    if (seen != null &&
        (isLive ? rematch.version < seen : rematch.version <= seen)) {
      return;
    }
    if (seen == null || rematch.version > seen) {
      _rematchVersions[sourceId] = rematch.version;
    }
    switch (rematch.status) {
      case RematchStatus.waiting:
        if (_myUserId == null && !_enrichmentDone.contains(sourceId)) {
          // Incoming or outgoing is unknown until the source battle loads.
          _unclassifiedRematches[sourceId] = rematch;
          _requestRematchEnrichment(sourceId);
          return;
        }
        _applyWaitingRematch(rematch, emit);
      case RematchStatus.matched:
        _unclassifiedRematches.remove(sourceId);
        _applyMatchedRematch(rematch, emit);
      case RematchStatus.expired:
        _unclassifiedRematches.remove(sourceId);
        _expire(_rematchItemId(sourceId), emit);
      case RematchStatus.cancelled:
        _unclassifiedRematches.remove(sourceId);
        _applyCancelledRematch(rematch, emit);
    }
  }

  void _applyWaitingRematch(
    RematchEntity rematch,
    Emitter<NotificationState> emit,
  ) {
    final String sourceId = rematch.sourceBattleId;
    final String itemId = _rematchItemId(sourceId);
    final NotificationItem? existing = state.item(itemId);
    if (!rematch.expiresAt.isAfter(_now())) {
      // The backend expires lazily. A rematch never shown is dropped.
      _expire(itemId, emit);
      return;
    }
    final String? me = _myUserId;
    // Without the own id (failed load) show it: a lost request is worse.
    final bool isIncoming = me == null || !rematch.hasConsentOf(me);
    final RematchNotificationPayload? previous = _rematchPayload(existing);
    final ({String? nickname, String disciplineCode})? details =
        _rematchDetails[sourceId];
    final RematchNotificationPayload payload = RematchNotificationPayload(
      rematch: rematch,
      isIncoming: isIncoming,
      opponentNickname: previous?.opponentNickname ?? details?.nickname,
      disciplineCode: previous?.disciplineCode ?? details?.disciplineCode,
    );
    final NotificationItem next = existing == null
        ? NotificationItem(
            kind: NotificationKind.rematch,
            resourceId: sourceId,
            expiresAt: rematch.expiresAt,
            isPrompt: isIncoming,
            payload: payload,
          )
        : existing.copyWith(
            expiresAt: rematch.expiresAt,
            isPrompt: isIncoming,
            payload: payload,
          );
    _putItem(next, emit);
    if (existing == null || existing.expiresAt != next.expiresAt) {
      _scheduleDeadline(next);
    }
    _requestRematchEnrichment(sourceId);
    if (isIncoming && !(existing?.isPrompt ?? false)) {
      add(const NotificationActivityRefreshRequested());
    }
  }

  void _applyMatchedRematch(
    RematchEntity rematch,
    Emitter<NotificationState> emit,
  ) {
    final String sourceId = rematch.sourceBattleId;
    final String itemId = _rematchItemId(sourceId);
    final NotificationItem? existing = state.item(itemId);
    _cancelTimers(itemId);
    final String? battleId = rematch.battleId;
    final bool opens = battleId != null && _openedBattles.add(battleId);
    if (existing == null && !opens) return;
    emit(
      state.copyWith(
        items: existing == null ? null : _itemsWithout(itemId),
        battleToOpen: opens ? battleId : null,
        notices: opens
            ? _noticesWith(
                NotificationKind.rematch,
                NotificationNoticeType.accepted,
                sourceId,
                _rematchPayload(existing)?.opponentNickname ??
                    _rematchDetails[sourceId]?.nickname,
              )
            : null,
      ),
    );
  }

  void _applyCancelledRematch(
    RematchEntity rematch,
    Emitter<NotificationState> emit,
  ) {
    final String sourceId = rematch.sourceBattleId;
    final NotificationItem? existing = state.item(_rematchItemId(sourceId));
    if (existing == null) return;
    final bool isIncoming = _rematchPayload(existing)?.isIncoming ?? true;
    final bool silent = _ownDeclines.contains(sourceId) || existing.isExpired;
    _removeItem(
      existing.id,
      emit,
      notice: silent
          ? null
          : isIncoming
          ? NotificationNoticeType.cancelled
          : NotificationNoticeType.declined,
    );
  }

  Future<void> _acceptRematch(
    NotificationItem item,
    Emitter<NotificationState> emit,
  ) async {
    final int session = _session;
    _putItem(
      item.copyWith(
        action: const NotificationAction(
          status: NotificationActionStatus.accepting,
        ),
      ),
      emit,
    );
    final Either<Failure, RematchEntity> result = await _requestRematch(
      ResultParamsEntity(battleId: item.resourceId),
    );
    if (emit.isDone || session != _session) return;
    result.match(
      (Failure failure) => _onRematchAcceptFailed(item.id, failure, emit),
      (RematchEntity rematch) {
        _clearAction(item.id, emit);
        _ingestRematch(rematch, emit);
      },
    );
  }

  void _onRematchAcceptFailed(
    String itemId,
    Failure failure,
    Emitter<NotificationState> emit,
  ) {
    final NotificationItem? current = state.item(itemId);
    // Already settled by a push (e.g. CANCELLED): no second notice.
    if (current == null) return;
    if (failure.hasCode(ApiErrorCodes.rematchExpired)) {
      _clearAction(itemId, emit);
      _expire(itemId, emit);
      return;
    }
    if (failure.hasCode(ApiErrorCodes.rematchNotAllowed)) {
      _removeItem(itemId, emit, notice: NotificationNoticeType.cancelled);
      return;
    }
    if (failure.hasCode(ApiErrorCodes.activityConflict)) {
      emit(state.copyWith(isBusy: true));
    }
    _putItem(
      current.copyWith(
        action: NotificationAction(
          status: NotificationActionStatus.failed,
          failure: failure,
        ),
      ),
      emit,
    );
  }

  /// The backend has no decline: cancel ends a waiting rematch for either
  /// participant.
  Future<void> _declineRematch(
    NotificationItem item,
    Emitter<NotificationState> emit,
  ) async {
    final int session = _session;
    _ownDeclines.add(item.resourceId);
    _putItem(
      item.copyWith(
        action: const NotificationAction(
          status: NotificationActionStatus.declining,
        ),
      ),
      emit,
    );
    final Either<Failure, Unit> result = await _cancelRematch(
      ResultParamsEntity(battleId: item.resourceId),
    );
    if (emit.isDone || session != _session) return;
    result.match((Failure failure) {
      _ownDeclines.remove(item.resourceId);
      final NotificationItem? current = state.item(item.id);
      if (current == null) return;
      _putItem(
        current.copyWith(
          action: NotificationAction(
            status: NotificationActionStatus.failed,
            failure: failure,
          ),
        ),
        emit,
      );
    }, (_) => _removeItem(item.id, emit));
  }

  void _requestRematchEnrichment(String sourceId) {
    if (_enrichmentStarted.add(sourceId)) {
      add(_RematchEnrichmentRequested(sourceId));
    }
  }

  Future<void> _onRematchEnrichmentRequested(
    _RematchEnrichmentRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final int session = _session;
    final String sourceId = event.sourceBattleId;
    final Either<Failure, BattleResultEntity> result = await _getResult(
      ResultParamsEntity(battleId: sourceId),
    );
    if (emit.isDone || session != _session) return;
    _enrichmentDone.add(sourceId);
    final BattleResultEntity? loaded = result.toNullable();
    if (loaded != null) {
      if (loaded.myUserId.isNotEmpty) _myUserId = loaded.myUserId;
      final ({String? nickname, String disciplineCode}) details = (
        nickname: loaded.players.isEmpty ? null : loaded.opponent.nickname,
        disciplineCode: loaded.disciplineCode,
      );
      _rematchDetails[sourceId] = details;
      final NotificationItem? item = state.item(_rematchItemId(sourceId));
      final RematchNotificationPayload? payload = _rematchPayload(item);
      if (item != null && payload != null) {
        _putItem(
          item.copyWith(
            payload: payload.copyWith(
              opponentNickname: details.nickname,
              disciplineCode: details.disciplineCode,
            ),
          ),
          emit,
        );
      }
    }
    // Apply what waited for the own id: all of them once it is known,
    // otherwise only this one (shown as incoming).
    final List<String> ready = _myUserId != null
        ? _unclassifiedRematches.keys.toList()
        : <String>[if (_unclassifiedRematches.containsKey(sourceId)) sourceId];
    for (final String id in ready) {
      final RematchEntity? rematch = _unclassifiedRematches.remove(id);
      if (rematch != null) _applyWaitingRematch(rematch, emit);
    }
  }

  Future<void> _onRematchRecoveryRequested(
    _RematchRecoveryRequested event,
    Emitter<NotificationState> emit,
  ) async {
    if (!_isSignedIn) return;
    final List<String> sourceIds = <String>[
      for (final NotificationItem item in state.items)
        if (item.kind == NotificationKind.rematch && !item.isExpired)
          item.resourceId,
    ];
    if (sourceIds.isEmpty) return;
    final int session = _session;
    final List<Either<Failure, RematchEntity?>> results = await Future.wait(
      sourceIds.map(
        (String id) => _getRematch(ResultParamsEntity(battleId: id)),
      ),
    );
    if (emit.isDone || session != _session) return;
    for (int i = 0; i < sourceIds.length; i++) {
      results[i].match((_) {}, (RematchEntity? rematch) {
        if (rematch != null) {
          _ingestRematch(rematch, emit);
        } else {
          // The server no longer knows it: drop it silently.
          _removeItem(_rematchItemId(sourceIds[i]), emit);
        }
      });
    }
  }

  String _rematchItemId(String sourceBattleId) =>
      NotificationItem.idOf(NotificationKind.rematch, sourceBattleId);

  RematchNotificationPayload? _rematchPayload(NotificationItem? item) =>
      switch (item?.payload) {
        final RematchNotificationPayload payload => payload,
        _ => null,
      };

  // ---------------------------------------------------------------------
  // Friends kinds: session and recovery.

  void _onSignedInUserChanged(
    _SignedInUserChanged event,
    Emitter<NotificationState> emit,
  ) {
    final String? previous = _userId;
    _userId = event.userId;
    // Token refreshes repeat the id; sign-in and sign-out are handled by
    // the signed-in flag. Only another account without a sign-out remains.
    if (previous == null || event.userId == null || previous == event.userId) {
      return;
    }
    _clearSession();
    emit(NotificationState(isConnected: state.isConnected));
    if (_isSignedIn) add(const _FriendsRecoveryRequested(baseline: true));
  }

  Future<void> _onFriendsRecoveryRequested(
    _FriendsRecoveryRequested event,
    Emitter<NotificationState> emit,
  ) async {
    // Survives a restart of the recovery by a later request.
    if (event.baseline) _reshowPending = true;
    if (!_isSignedIn) return;
    final int session = _session;
    final int run = ++_friendsRecovery;
    _friendsRecovering = true;
    final int activityRun = ++_activityRun;
    final (
      Either<Failure, FriendRequestsPageEntity> requests,
      Either<Failure, DuelInvitationsSnapshotEntity> invitations,
      Either<Failure, ActivityEntity> activity,
    ) = await (
      _getFriendRequests(
        const FriendRequestsParamsEntity(size: friendRequestsPageSize),
      ),
      _getIncomingDuelInvitations(const NoParams()),
      _getActivity(const NoParams()),
    ).wait;
    if (_isStaleRecovery(emit, session, run)) return;

    // Host side: the own waiting room's invitation, then the outcome of a
    // known own invitation the room no longer lists.
    final ActivityEntity? own = activity.toNullable();
    final String? ownRoomId =
        own != null &&
            own.type == ActivityType.privateDuel &&
            own.resourceKind == ActivityResourceKind.duel
        ? own.resourceId
        : null;
    Either<Failure, DuelInvitationsSnapshotEntity>? room;
    if (ownRoomId != null) {
      room = await _getRoomInvitations(
        RoomInvitationsParamsEntity(duelId: ownRoomId),
      );
      if (_isStaleRecovery(emit, session, run)) return;
    }
    final String? knownOutgoingId = _outgoingItem()?.resourceId;
    final bool roomListsKnown =
        room?.toNullable()?.invitations.any(
          (DuelInvitationEntity i) => i.id == knownOutgoingId,
        ) ??
        false;
    Either<Failure, DuelInvitationEntity>? outgoing;
    if (knownOutgoingId != null && !roomListsKnown) {
      outgoing = await _getDuelInvitation(
        DuelInvitationParamsEntity(invitationId: knownOutgoingId),
      );
      if (_isStaleRecovery(emit, session, run)) return;
    }

    // From here to the end no await: the snapshot and the buffered pushes
    // are applied in one step, so nothing slips in between.
    if (activityRun == _activityRun && own != null) {
      emit(state.copyWith(isBusy: !own.isNone));
    }
    requests.match(
      (_) {},
      (FriendRequestsPageEntity page) => _applyRequestsSnapshot(page, emit),
    );
    invitations.match((_) {}, (DuelInvitationsSnapshotEntity snapshot) {
      _clockOffset = snapshot.clockOffset;
      _applyInvitationsSnapshot(snapshot, emit);
    });
    room?.match((_) {}, (DuelInvitationsSnapshotEntity snapshot) {
      for (final DuelInvitationEntity item in snapshot.invitations) {
        _applyInvitation(item, emit, allowEqual: true);
      }
    });
    outgoing?.match(
      (Failure failure) {
        if (!failure.hasCode(ApiErrorCodes.duelInvitationNotFound)) return;
        final NotificationItem? item = _outgoingItem();
        if (item == null) return;
        _tombstoneInvitation(item.resourceId);
        _removeItem(item.id, emit);
        // Lost ACCEPTED after a server restart: the battle is in activity.
        final String? battleId = own?.type == ActivityType.battle
            ? own?.battleId
            : null;
        if (battleId != null) {
          _openBattle(
            battleId,
            emit,
            kind: NotificationKind.duelInvitation,
            resourceId: item.resourceId,
            nickname: _playerNickname(item),
            isOutgoing: true,
          );
        }
      },
      (DuelInvitationEntity record) =>
          _applyInvitation(record, emit, allowEqual: true),
    );
    if (_reshowPending) {
      _reshowPending = false;
      _showFriendsPrompts(emit);
    }
    final List<Object> buffered = List<Object>.of(_friendsBuffer);
    _friendsBuffer.clear();
    _friendsRecovering = false;
    for (final Object record in buffered) {
      switch (record) {
        case final RelationshipEntity relationship:
          _applyRelationship(relationship, emit);
        case final DuelInvitationEntity invitation:
          _applyInvitation(invitation, emit);
      }
    }
  }

  /// A newer recovery or another session owns the buffer and the flag.
  bool _isStaleRecovery(
    Emitter<NotificationState> emit,
    int session,
    int run,
  ) => emit.isDone || session != _session || run != _friendsRecovery;

  /// Startup and reconnect show every recovered friends prompt again.
  void _showFriendsPrompts(Emitter<NotificationState> emit) {
    bool isFriendsHidden(NotificationItem item) =>
        item.kind != NotificationKind.rematch && _isHiddenPending(item);
    if (!state.items.any(isFriendsHidden)) return;
    emit(
      state.copyWith(
        items: List<NotificationItem>.unmodifiable(<NotificationItem>[
          for (final NotificationItem item in state.items)
            isFriendsHidden(item) ? item.copyWith(isHidden: false) : item,
        ]),
      ),
    );
  }

  void _onFriendshipReceived(
    _FriendshipReceived event,
    Emitter<NotificationState> emit,
  ) {
    if (!_isSignedIn) return;
    if (_friendsRecovering) {
      _friendsBuffer.add(event.relationship);
      return;
    }
    _applyRelationship(event.relationship, emit);
  }

  void _onDuelInvitationReceived(
    _DuelInvitationReceived event,
    Emitter<NotificationState> emit,
  ) {
    if (!_isSignedIn) return;
    // Navigation of an own accept never waits for a recovery.
    _resolveOwnAccept(event.invitation, emit);
    if (_friendsRecovering) {
      _friendsBuffer.add(event.invitation);
      return;
    }
    _applyInvitation(event.invitation, emit);
  }

  // ---------------------------------------------------------------------
  // Friend request kind.

  /// Incoming PENDING requests as of the request time. Absence is not
  /// proof of an outcome for a card being acted on or showing Done.
  void _applyRequestsSnapshot(
    FriendRequestsPageEntity page,
    Emitter<NotificationState> emit,
  ) {
    final Set<String> pending = <String>{};
    for (final RelationshipEntity item in page.items) {
      if (!item.isIncoming || !item.status.isPending) continue;
      final int? tombstone = _requestTombstones[item.id];
      if (tombstone != null && tombstone >= item.version) continue;
      _raise(_requestVersions, item.id, item.version);
      pending.add(item.id);
      _putRequest(item, emit);
    }
    for (final NotificationItem item in List<NotificationItem>.of(
      state.items,
    )) {
      if (item.kind != NotificationKind.friendRequest ||
          pending.contains(item.resourceId) ||
          item.isActionInFlight ||
          item.isExpired) {
        continue;
      }
      _removeItem(item.id, emit);
    }
  }

  void _putRequest(
    RelationshipEntity relationship,
    Emitter<NotificationState> emit,
  ) {
    final NotificationItem? existing = state.item(
      _requestItemId(relationship.id),
    );
    final FriendRequestNotificationPayload? previous = _requestPayload(
      existing,
    );
    if (previous != null &&
        previous.relationship.version > relationship.version) {
      return;
    }
    final FriendRequestNotificationPayload payload =
        FriendRequestNotificationPayload(relationship: relationship);
    _putItem(
      existing == null
          ? NotificationItem(
              kind: NotificationKind.friendRequest,
              resourceId: relationship.id,
              expiresAt: NotificationItem.noDeadline.add(
                Duration(
                  microseconds: relationship.createdAt.microsecondsSinceEpoch,
                ),
              ),
              isPrompt: true,
              payload: payload,
            )
          : existing.copyWith(payload: payload),
      emit,
    );
  }

  void _applyRelationship(
    RelationshipEntity record,
    Emitter<NotificationState> emit, {
    bool allowEqual = false,
  }) {
    final int? known = _requestVersions[record.id];
    if (known != null &&
        (allowEqual ? record.version < known : record.version <= known)) {
      return;
    }
    _raise(_requestVersions, record.id, record.version);
    if (!record.isIncoming) {
      // Own outgoing request: only "accepted" is told (no toast for a
      // declined request, none for a request to yourself).
      if (record.status == RelationshipStatus.accepted &&
          _noticedRelationships.add('${record.id}:accepted')) {
        emit(
          state.copyWith(
            notices: _noticesWith(
              NotificationKind.friendRequest,
              NotificationNoticeType.accepted,
              record.id,
              record.recipient.nickname,
              isOutgoing: true,
            ),
          ),
        );
      }
      return;
    }
    if (record.status.isPending) {
      final int? tombstone = _requestTombstones[record.id];
      if (tombstone != null && tombstone >= record.version) return;
      _putRequest(record, emit);
      return;
    }
    _requestTombstones[record.id] = record.version;
    final NotificationItem? item = state.item(_requestItemId(record.id));
    if (item == null || item.isExpired) return;
    final NotificationActionStatus? action = item.action?.status;
    final bool ownAccept =
        action == NotificationActionStatus.accepting ||
        action == NotificationActionStatus.reconciling;
    if (record.status == RelationshipStatus.accepted &&
        ownAccept &&
        !item.isHidden) {
      // Done state: "You and {nickname} are now friends." for a moment.
      _putItem(
        item.copyWith(
          isExpired: true,
          resetAction: true,
          payload: FriendRequestNotificationPayload(
            relationship: record,
            isDone: true,
          ),
        ),
        emit,
      );
      _linger(item.id);
      return;
    }
    // Resolved elsewhere (or declined here): removed silently.
    _removeItem(item.id, emit);
  }

  Future<void> _respondToRequest(
    NotificationItem item, {
    required bool accept,
    required Emitter<NotificationState> emit,
  }) async {
    final int session = _session;
    _setAction(
      item.id,
      accept
          ? NotificationActionStatus.accepting
          : NotificationActionStatus.declining,
      emit,
    );
    final FriendRequestParamsEntity params = FriendRequestParamsEntity(
      requestId: item.resourceId,
    );
    final Either<Failure, RelationshipEntity> result = accept
        ? await _acceptFriendRequest(params)
        : await _declineFriendRequest(params);
    if (emit.isDone || session != _session) return;
    final Failure? failure = result.getLeft();
    if (failure == null) {
      _applyRelationship(result.toNullable()!, emit, allowEqual: true);
      _settleAction(item.id, emit);
      return;
    }
    if (failure.hasCode(ApiErrorCodes.friendRequestNotFound)) {
      _tombstoneRequest(item.resourceId);
      _removeItem(item.id, emit);
      return;
    }
    if (_isUncertain(failure) ||
        failure.hasCode(ApiErrorCodes.friendRequestNotPending)) {
      await _reconcileRequest(item, failure, session, emit);
      return;
    }
    _fail(item.id, failure, emit);
  }

  Future<void> _reconcileRequest(
    NotificationItem item,
    Failure original,
    int session,
    Emitter<NotificationState> emit,
  ) async {
    _setAction(item.id, NotificationActionStatus.reconciling, emit);
    final Either<Failure, RelationshipEntity> result = await _getFriendRequest(
      FriendRequestParamsEntity(requestId: item.resourceId),
    );
    if (emit.isDone || session != _session) return;
    result.match(
      (Failure failure) {
        if (failure.hasCode(ApiErrorCodes.friendRequestNotFound)) {
          _tombstoneRequest(item.resourceId);
          _removeItem(item.id, emit);
        } else {
          _fail(item.id, original, emit);
        }
      },
      (RelationshipEntity relationship) {
        if (relationship.status.isPending) {
          _applyRelationship(relationship, emit);
          _fail(item.id, original, emit);
          return;
        }
        _applyRelationship(relationship, emit, allowEqual: true);
        _settleAction(item.id, emit);
      },
    );
  }

  void _tombstoneRequest(String id) {
    final int? known = _requestVersions[id];
    if (known != null) _requestTombstones[id] = known;
  }

  String _requestItemId(String relationshipId) =>
      NotificationItem.idOf(NotificationKind.friendRequest, relationshipId);

  FriendRequestNotificationPayload? _requestPayload(NotificationItem? item) =>
      switch (item?.payload) {
        final FriendRequestNotificationPayload payload => payload,
        _ => null,
      };

  // ---------------------------------------------------------------------
  // Room invitation kind.

  void _applyInvitationsSnapshot(
    DuelInvitationsSnapshotEntity snapshot,
    Emitter<NotificationState> emit,
  ) {
    final Set<String> pending = <String>{};
    for (final DuelInvitationEntity item in snapshot.invitations) {
      if (!item.isIncoming || !item.status.isPending) continue;
      final int? tombstone = _invitationTombstones[item.id];
      if (tombstone != null && tombstone >= item.version) continue;
      _raise(_invitationVersions, item.id, item.version);
      pending.add(item.id);
      _putIncomingInvitation(item, emit);
    }
    for (final NotificationItem item in List<NotificationItem>.of(
      state.items,
    )) {
      if (item.kind != NotificationKind.duelInvitation ||
          !item.isPrompt ||
          pending.contains(item.resourceId) ||
          item.isActionInFlight ||
          item.isExpired) {
        continue;
      }
      // Gone while shown (server restart, a missed terminal push).
      final DuelInvitationNotificationPayload? payload = _invitationPayload(
        item,
      );
      if (payload == null) continue;
      _tombstoneInvitation(item.resourceId);
      _closeRoomUnavailable(
        item,
        DuelInvitationNotificationPayload(
          invitation: payload.invitation,
          isGone: true,
        ),
        emit,
      );
    }
  }

  /// Local-clock deadline of a server `expiresAt`.
  DateTime _localDeadline(DuelInvitationEntity invitation) =>
      invitation.expiresAt.subtract(_clockOffset);

  void _putIncomingInvitation(
    DuelInvitationEntity invitation,
    Emitter<NotificationState> emit,
  ) {
    final String itemId = _invitationItemId(invitation.id);
    final NotificationItem? existing = state.item(itemId);
    final DuelInvitationNotificationPayload? previous = _invitationPayload(
      existing,
    );
    if (previous != null && previous.invitation.version > invitation.version) {
      return;
    }
    final DateTime deadline = _localDeadline(invitation);
    if (!deadline.isAfter(_now())) {
      // Never shown: dropped; shown: the expiry path.
      if (existing != null) _expire(itemId, emit);
      return;
    }
    final DuelInvitationNotificationPayload payload =
        DuelInvitationNotificationPayload(invitation: invitation);
    final NotificationItem next = existing == null
        ? NotificationItem(
            kind: NotificationKind.duelInvitation,
            resourceId: invitation.id,
            expiresAt: deadline,
            isPrompt: true,
            payload: payload,
          )
        : existing.copyWith(expiresAt: deadline, payload: payload);
    _putItem(next, emit);
    if (existing == null || existing.expiresAt != next.expiresAt) {
      _scheduleDeadline(next);
    }
    // A fresh busy flag for the new prompt.
    if (existing == null) add(const NotificationActivityRefreshRequested());
  }

  void _applyInvitation(
    DuelInvitationEntity record,
    Emitter<NotificationState> emit, {
    bool allowEqual = false,
  }) {
    if (!record.isIncoming) {
      _applyOutgoing(record, emit, allowEqual: allowEqual);
      return;
    }
    final int? known = _invitationVersions[record.id];
    if (known != null &&
        (allowEqual ? record.version < known : record.version <= known)) {
      return;
    }
    _raise(_invitationVersions, record.id, record.version);
    if (record.status.isPending) {
      final int? tombstone = _invitationTombstones[record.id];
      if (tombstone != null && tombstone >= record.version) return;
      _putIncomingInvitation(record, emit);
      return;
    }
    _invitationTombstones[record.id] = record.version;
    final NotificationItem? item = state.item(_invitationItemId(record.id));
    if (item == null) return;
    final DuelInvitationNotificationPayload payload =
        DuelInvitationNotificationPayload(invitation: record);
    switch (record.status) {
      case DuelInvitationStatus.pending:
        return;
      case DuelInvitationStatus.accepted:
      case DuelInvitationStatus.declined:
        // Accepted: the toast and the battle come from the own accept.
        _removeItem(item.id, emit);
      case DuelInvitationStatus.expired:
      case DuelInvitationStatus.cancelled:
        if (payload.isRoomUnavailable) {
          _closeRoomUnavailable(item, payload, emit);
        } else if (record.status == DuelInvitationStatus.expired) {
          _clearAction(item.id, emit);
          final NotificationItem? current = state.item(item.id);
          if (current != null) {
            _putItem(current.copyWith(payload: payload), emit);
          }
          _expire(item.id, emit);
        } else {
          // SENDER_CANCELLED / FRIEND_REMOVED, visible or hidden.
          _putItem(item.copyWith(payload: payload), emit);
          _removeItem(item.id, emit, notice: NotificationNoticeType.cancelled);
        }
    }
  }

  /// "This room is no longer available.": a visible card stays closed for
  /// [expiredLinger]; a hidden one is removed with a `cancelled` notice.
  void _closeRoomUnavailable(
    NotificationItem item,
    DuelInvitationNotificationPayload payload,
    Emitter<NotificationState> emit,
  ) {
    _cancelTimers(item.id);
    final NotificationItem closed = item.copyWith(payload: payload);
    if (item.isHidden) {
      _putItem(closed, emit);
      _removeItem(item.id, emit, notice: NotificationNoticeType.cancelled);
      return;
    }
    _putItem(closed.copyWith(isExpired: true, resetAction: true), emit);
    _linger(item.id);
  }

  /// The host's own invitation: tracked (not a card) for its outcome.
  void _applyOutgoing(
    DuelInvitationEntity record,
    Emitter<NotificationState> emit, {
    bool allowEqual = false,
  }) {
    final int? known = _invitationVersions[record.id];
    if (known != null &&
        (allowEqual ? record.version < known : record.version <= known)) {
      return;
    }
    _raise(_invitationVersions, record.id, record.version);
    final String itemId = _invitationItemId(record.id);
    if (record.status.isPending) {
      final int? tombstone = _invitationTombstones[record.id];
      if (tombstone != null && tombstone >= record.version) return;
      final DateTime deadline = _localDeadline(record);
      if (!deadline.isAfter(_now())) return;
      // At most one pending invitation per room: a newer one replaces it.
      for (final NotificationItem other in List<NotificationItem>.of(
        state.items,
      )) {
        if (other.kind == NotificationKind.duelInvitation &&
            !other.isPrompt &&
            other.id != itemId) {
          _removeItem(other.id, emit);
        }
      }
      final NotificationItem? existing = state.item(itemId);
      final DuelInvitationNotificationPayload payload =
          DuelInvitationNotificationPayload(invitation: record);
      final NotificationItem next = existing == null
          ? NotificationItem(
              kind: NotificationKind.duelInvitation,
              resourceId: record.id,
              expiresAt: deadline,
              isPrompt: false,
              payload: payload,
            )
          : existing.copyWith(expiresAt: deadline, payload: payload);
      _putItem(next, emit);
      if (existing == null || existing.expiresAt != next.expiresAt) {
        _scheduleDeadline(next);
      }
      return;
    }
    _invitationTombstones[record.id] = record.version;
    _removeItem(itemId, emit);
    final NotificationNoticeType? type = switch (record.status) {
      DuelInvitationStatus.accepted => NotificationNoticeType.accepted,
      DuelInvitationStatus.declined => NotificationNoticeType.declined,
      DuelInvitationStatus.expired => NotificationNoticeType.expired,
      DuelInvitationStatus.cancelled => switch (record.reason) {
        // Own withdrawal or own room cancellation: nothing to tell.
        DuelInvitationReason.senderCancelled ||
        DuelInvitationReason.duelCancelled => null,
        _ => NotificationNoticeType.cancelled,
      },
      DuelInvitationStatus.pending => null,
    };
    if (type == null ||
        !_noticedInvitations.add('${record.id}:${record.status.name}')) {
      return;
    }
    final String? battleId = record.battleId;
    if (type == NotificationNoticeType.accepted && battleId != null) {
      // Once per battle id, shared with the room screen and the invitee.
      _openBattle(
        battleId,
        emit,
        kind: NotificationKind.duelInvitation,
        resourceId: record.id,
        nickname: record.recipient.nickname,
        isOutgoing: true,
      );
      return;
    }
    emit(
      state.copyWith(
        notices: _noticesWith(
          NotificationKind.duelInvitation,
          type,
          record.id,
          record.recipient.nickname,
          isOutgoing: true,
          reason: record.reason,
        ),
      ),
    );
  }

  /// Opens the battle of an own accept, whichever of the push and the HTTP
  /// answer arrives first; runs before any version check.
  void _resolveOwnAccept(
    DuelInvitationEntity record,
    Emitter<NotificationState> emit,
  ) {
    if (!_acceptingInvitations.contains(record.id)) return;
    final String? battleId = record.battleId;
    if (record.status == DuelInvitationStatus.accepted && battleId != null) {
      _acceptingInvitations.remove(record.id);
      _openBattle(
        battleId,
        emit,
        kind: NotificationKind.duelInvitation,
        resourceId: record.id,
        nickname: record.host.nickname,
      );
    } else if (record.status.isTerminal) {
      _acceptingInvitations.remove(record.id);
    }
  }

  Future<void> _acceptInvitation(
    NotificationItem item,
    Emitter<NotificationState> emit,
  ) async {
    final int session = _session;
    final String id = item.resourceId;
    _acceptingInvitations.add(id);
    _setAction(item.id, NotificationActionStatus.accepting, emit);
    final Either<Failure, DuelInvitationEntity> result =
        await _acceptDuelInvitation(
          DuelInvitationParamsEntity(invitationId: id),
        );
    if (emit.isDone || session != _session) return;
    final Failure? failure = result.getLeft();
    if (failure == null) {
      final DuelInvitationEntity invitation = result.toNullable()!;
      if (invitation.status == DuelInvitationStatus.accepted &&
          invitation.battleId == null) {
        // ACCEPTED without a battle id: the battle is in own activity.
        await _reconcileInvitation(item, null, session, emit, accepting: true);
        return;
      }
      _resolveOwnAccept(invitation, emit);
      _applyInvitation(invitation, emit, allowEqual: true);
      _settleAction(item.id, emit);
      return;
    }
    if (failure.hasCode(ApiErrorCodes.activityConflict)) {
      _acceptingInvitations.remove(id);
      emit(state.copyWith(isBusy: true));
      _fail(item.id, failure, emit);
      add(const NotificationActivityRefreshRequested());
      return;
    }
    if (failure.hasCode(ApiErrorCodes.duelInvitationExpired)) {
      // 410 is terminal; the server committed EXPIRED before answering.
      _acceptingInvitations.remove(id);
      _tombstoneInvitation(id);
      _clearAction(item.id, emit);
      _expire(item.id, emit);
      return;
    }
    if (_isUncertain(failure) ||
        failure.hasCode(ApiErrorCodes.duelInvitationNotPending) ||
        failure.hasCode(ApiErrorCodes.duelInvitationNotFound)) {
      await _reconcileInvitation(item, failure, session, emit, accepting: true);
      return;
    }
    // CONTENT_UNAVAILABLE, FORBIDDEN, RATE_LIMITED, ...: still pending.
    _acceptingInvitations.remove(id);
    _fail(item.id, failure, emit);
  }

  Future<void> _declineInvitation(
    NotificationItem item,
    Emitter<NotificationState> emit,
  ) async {
    final int session = _session;
    _setAction(item.id, NotificationActionStatus.declining, emit);
    final Either<Failure, DuelInvitationEntity> result =
        await _declineDuelInvitation(
          DuelInvitationParamsEntity(invitationId: item.resourceId),
        );
    if (emit.isDone || session != _session) return;
    final Failure? failure = result.getLeft();
    if (failure == null) {
      _applyInvitation(result.toNullable()!, emit, allowEqual: true);
      _settleAction(item.id, emit);
      return;
    }
    if (_isUncertain(failure) ||
        failure.hasCode(ApiErrorCodes.matchAlreadyFound) ||
        failure.hasCode(ApiErrorCodes.duelInvitationNotFound)) {
      await _reconcileInvitation(
        item,
        failure,
        session,
        emit,
        accepting: false,
      );
      return;
    }
    _fail(item.id, failure, emit);
  }

  /// Re-reads the invitation and own activity after an uncertain answer.
  /// [original] is shown when the invitation is still pending; `null` means
  /// the command itself succeeded.
  Future<void> _reconcileInvitation(
    NotificationItem item,
    Failure? original,
    int session,
    Emitter<NotificationState> emit, {
    required bool accepting,
  }) async {
    final String id = item.resourceId;
    _setAction(item.id, NotificationActionStatus.reconciling, emit);
    final int activityRun = ++_activityRun;
    final (
      Either<Failure, DuelInvitationEntity> invitation,
      Either<Failure, ActivityEntity> activity,
    ) = await (
      _getDuelInvitation(DuelInvitationParamsEntity(invitationId: id)),
      _getActivity(const NoParams()),
    ).wait;
    if (emit.isDone || session != _session) return;
    final ActivityEntity? own = activity.toNullable();
    if (activityRun == _activityRun && own != null) {
      emit(state.copyWith(isBusy: !own.isNone));
    }
    final String? activityBattle = accepting && own?.type == ActivityType.battle
        ? own?.battleId
        : null;
    final String? hostNickname = _playerNickname(item);
    invitation.match(
      (Failure failure) {
        _acceptingInvitations.remove(id);
        final bool gone = failure.hasCode(ApiErrorCodes.duelInvitationNotFound);
        final NotificationItem? current = state.item(item.id);
        if (activityBattle != null && (gone || original == null)) {
          // Lost ACCEPTED (server restart): the battle is in activity.
          _tombstoneInvitation(id);
          _removeItem(item.id, emit);
          _openBattle(
            activityBattle,
            emit,
            kind: NotificationKind.duelInvitation,
            resourceId: id,
            nickname: hostNickname,
          );
        } else if (gone && current != null) {
          _tombstoneInvitation(id);
          final DuelInvitationNotificationPayload? payload = _invitationPayload(
            current,
          );
          if (payload != null) {
            _closeRoomUnavailable(
              current,
              DuelInvitationNotificationPayload(
                invitation: payload.invitation,
                isGone: true,
              ),
              emit,
            );
          }
        } else {
          // Unknown outcome: keep the card; Accept is idempotent, so a
          // retry is safe.
          _fail(item.id, original ?? failure, emit);
        }
      },
      (DuelInvitationEntity record) {
        if (record.status == DuelInvitationStatus.accepted &&
            record.battleId == null &&
            activityBattle != null) {
          _acceptingInvitations.remove(id);
          _openBattle(
            activityBattle,
            emit,
            kind: NotificationKind.duelInvitation,
            resourceId: id,
            nickname: hostNickname,
          );
        }
        _resolveOwnAccept(record, emit);
        if (record.status.isPending) {
          _acceptingInvitations.remove(id);
          _applyInvitation(record, emit);
          if (original != null) {
            _fail(item.id, original, emit);
          } else {
            _clearAction(item.id, emit);
          }
          return;
        }
        _applyInvitation(record, emit, allowEqual: true);
        _settleAction(item.id, emit);
      },
    );
  }

  /// When an activity read shows the room of the host's own invitation is
  /// no longer the own activity, the invitation is re-read: a lost
  /// ACCEPTED push still reaches the host.
  void _checkOutgoingInvitation(ActivityEntity activity) {
    final NotificationItem? item = _outgoingItem();
    final DuelInvitationNotificationPayload? payload = _invitationPayload(item);
    if (item == null || payload == null) return;
    final bool stillWaiting =
        activity.type == ActivityType.privateDuel &&
        activity.resourceId == payload.invitation.duelId;
    if (!stillWaiting) add(const _OutgoingInvitationCheckRequested());
  }

  Future<void> _onOutgoingInvitationCheckRequested(
    _OutgoingInvitationCheckRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final NotificationItem? item = _outgoingItem();
    if (!_isSignedIn || item == null) return;
    final int session = _session;
    final Either<Failure, DuelInvitationEntity> result =
        await _getDuelInvitation(
          DuelInvitationParamsEntity(invitationId: item.resourceId),
        );
    if (emit.isDone || session != _session) return;
    result.match(
      (Failure failure) {
        if (failure.hasCode(ApiErrorCodes.duelInvitationNotFound)) {
          _tombstoneInvitation(item.resourceId);
          _removeItem(item.id, emit);
        }
      },
      (DuelInvitationEntity record) =>
          _applyInvitation(record, emit, allowEqual: true),
    );
  }

  void _openBattle(
    String battleId,
    Emitter<NotificationState> emit, {
    required NotificationKind kind,
    required String resourceId,
    String? nickname,
    bool isOutgoing = false,
  }) {
    if (!_openedBattles.add(battleId)) return;
    emit(
      state.copyWith(
        battleToOpen: battleId,
        notices: _noticesWith(
          kind,
          NotificationNoticeType.accepted,
          resourceId,
          nickname,
          isOutgoing: isOutgoing,
        ),
      ),
    );
  }

  void _tombstoneInvitation(String id) {
    final int? known = _invitationVersions[id];
    if (known != null) _invitationTombstones[id] = known;
  }

  NotificationItem? _outgoingItem() {
    for (final NotificationItem item in state.items) {
      if (item.kind == NotificationKind.duelInvitation && !item.isPrompt) {
        return item;
      }
    }
    return null;
  }

  String _invitationItemId(String invitationId) =>
      NotificationItem.idOf(NotificationKind.duelInvitation, invitationId);

  DuelInvitationNotificationPayload? _invitationPayload(
    NotificationItem? item,
  ) => switch (item?.payload) {
    final DuelInvitationNotificationPayload payload => payload,
    _ => null,
  };

  // ---------------------------------------------------------------------
  // Friends kinds: shared helpers.

  static void _raise(Map<String, int> versions, String id, int version) {
    final int? known = versions[id];
    if (known == null || version > known) versions[id] = version;
  }

  /// Transport failures and server errors do not say whether the command
  /// ran.
  static bool _isUncertain(Failure failure) => switch (failure) {
    ConnectionFailure() || TimeoutFailure() => true,
    ApiFailure(:final int statusCode) => statusCode >= 500,
    ParsingFailure() || UnexpectedFailure() => true,
    ValidationFailure() || StorageFailure() => false,
  };

  void _setAction(
    String itemId,
    NotificationActionStatus status,
    Emitter<NotificationState> emit,
  ) {
    final NotificationItem? item = state.item(itemId);
    if (item == null) return;
    _putItem(item.copyWith(action: NotificationAction(status: status)), emit);
  }

  void _fail(String itemId, Failure failure, Emitter<NotificationState> emit) {
    final NotificationItem? item = state.item(itemId);
    if (item == null || item.isExpired) return;
    _putItem(
      item.copyWith(
        action: NotificationAction(
          status: NotificationActionStatus.failed,
          failure: failure,
        ),
      ),
      emit,
    );
  }

  /// Clears an in-flight action the result did not settle (the card is
  /// still pending, e.g. a push already applied the same version).
  void _settleAction(String itemId, Emitter<NotificationState> emit) {
    final NotificationItem? item = state.item(itemId);
    if (item != null && item.isActionInFlight) _clearAction(itemId, emit);
  }

  // ---------------------------------------------------------------------
  // Helpers.

  /// A prompt that can take Accept or Decline now.
  NotificationItem? _actionable(String id) {
    final NotificationItem? item = state.item(id);
    if (item == null ||
        !item.isPrompt ||
        item.isExpired ||
        item.isActionInFlight) {
      return null;
    }
    return item;
  }

  String? _playerNickname(NotificationItem item) => switch (item.payload) {
    final RematchNotificationPayload payload => payload.opponentNickname,
    final FriendRequestNotificationPayload payload =>
      payload.relationship.otherPlayer.nickname,
    final DuelInvitationNotificationPayload payload =>
      payload.invitation.isIncoming
          ? payload.invitation.host.nickname
          : payload.invitation.recipient.nickname,
  };

  /// An own request of a friends kind (the host's invitation).
  static bool _isOutgoingFriendsItem(NotificationItem item) =>
      item.kind != NotificationKind.rematch && !item.isPrompt;

  static DuelInvitationReason? _invitationReasonOf(NotificationItem item) =>
      switch (item.payload) {
        final DuelInvitationNotificationPayload payload =>
          payload.invitation.reason,
        _ => null,
      };

  /// Replaces the item with the same id or appends it; no emit when equal.
  void _putItem(NotificationItem item, Emitter<NotificationState> emit) {
    final List<NotificationItem> items = <NotificationItem>[];
    bool replaced = false;
    for (final NotificationItem current in state.items) {
      if (current.id == item.id) {
        if (current == item) return;
        items.add(item);
        replaced = true;
      } else {
        items.add(current);
      }
    }
    if (!replaced) items.add(item);
    emit(state.copyWith(items: List<NotificationItem>.unmodifiable(items)));
  }

  void _clearAction(String itemId, Emitter<NotificationState> emit) {
    final NotificationItem? item = state.item(itemId);
    if (item == null || item.action == null) return;
    _putItem(item.copyWith(resetAction: true), emit);
  }

  void _removeItem(
    String itemId,
    Emitter<NotificationState> emit, {
    NotificationNoticeType? notice,
  }) {
    final NotificationItem? item = state.item(itemId);
    _cancelTimers(itemId);
    if (item == null) return;
    emit(
      state.copyWith(
        items: _itemsWithout(itemId),
        notices: notice == null
            ? null
            : _noticesWith(
                item.kind,
                notice,
                item.resourceId,
                _playerNickname(item),
                isOutgoing: _isOutgoingFriendsItem(item),
                reason: _invitationReasonOf(item),
              ),
      ),
    );
  }

  List<NotificationItem> _itemsWithout(String itemId) =>
      List<NotificationItem>.unmodifiable(
        state.items.where((NotificationItem item) => item.id != itemId),
      );

  List<NotificationNotice> _noticesWith(
    NotificationKind kind,
    NotificationNoticeType type,
    String resourceId,
    String? playerNickname, {
    bool isOutgoing = false,
    DuelInvitationReason? reason,
  }) => List<NotificationNotice>.unmodifiable(<NotificationNotice>[
    ...state.notices,
    NotificationNotice(
      id: 'notice-${_noticeSequence++}',
      kind: kind,
      type: type,
      resourceId: resourceId,
      playerNickname: playerNickname,
      isOutgoing: isOutgoing,
      invitationReason: reason,
    ),
  ]);

  void _cancelTimers(String itemId) {
    _deadlines.remove(itemId)?.cancel();
    _lingers.remove(itemId)?.cancel();
  }

  void _cancelAllTimers() {
    for (final Timer timer in _deadlines.values) {
      timer.cancel();
    }
    for (final Timer timer in _lingers.values) {
      timer.cancel();
    }
    _deadlines.clear();
    _lingers.clear();
  }

  void _clearSession() {
    _session++;
    _cancelAllTimers();
    _openedBattles.clear();
    _myUserId = null;
    _rematchVersions.clear();
    _unclassifiedRematches.clear();
    _enrichmentStarted.clear();
    _enrichmentDone.clear();
    _rematchDetails.clear();
    _ownDeclines.clear();
    _activityRun++;
    _friendsRecovery++;
    _friendsRecovering = false;
    _reshowPending = false;
    _friendsBuffer.clear();
    _requestVersions.clear();
    _requestTombstones.clear();
    _invitationVersions.clear();
    _invitationTombstones.clear();
    _acceptingInvitations.clear();
    _noticedRelationships.clear();
    _noticedInvitations.clear();
    _clockOffset = Duration.zero;
  }

  @override
  Future<void> close() async {
    _cancelAllTimers();
    for (final StreamSubscription<Object?> subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
