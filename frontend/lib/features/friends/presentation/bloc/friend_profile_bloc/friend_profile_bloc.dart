import 'dart:async';

import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/presentation/bloc/load_status.dart';
import 'package:skill_battles/core/presentation/bloc/signal_bloc.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_params_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_profile_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_status.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friend_profile_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/remove_friend_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/watch_friendship_changes_usecase.dart';

part 'friend_profile_event.dart';
part 'friend_profile_state.dart';

/// Basic profile of one accepted friend.
///
/// The server is the authority on the friendship: 404 FRIEND_NOT_FOUND
/// clears the profile into "no longer friends". A REMOVED push clears it
/// only when it carries the same relationship id; any other change for
/// this user triggers a refetch, so an old REMOVED never hides a newer
/// friendship. The latest read wins.
final class FriendProfileBloc
    extends SignalBloc<FriendProfileEvent, FriendProfileState> {
  FriendProfileBloc({
    required this._getFriendProfile,
    required this._removeFriend,
    required this._watchFriendshipChanges,
    required this._watchConnection,
  }) : super(const FriendProfileState()) {
    handle<FriendProfileStarted>(_onStarted, transformer: restartable());
    handle<FriendProfileRefreshRequested>(_onRefresh, transformer: restartable());
    handle<FriendProfileRemoveRequested>(_onRemove, transformer: droppable());
    handle<_FriendshipChanged>(_onFriendshipChanged);
    handle<_Reconnected>(_onReconnected);
  }

  final GetFriendProfileUsecase _getFriendProfile;
  final RemoveFriendUsecase _removeFriend;
  final WatchFriendshipChangesUsecase _watchFriendshipChanges;
  final WatchConnectionUsecase _watchConnection;

  StreamSubscription<RelationshipEntity>? _changesSubscription;
  StreamSubscription<RealtimeStatus>? _connectionSubscription;
  RealtimeStatus? _connection;
  int _loadVersion = 0;

  Future<void> _onStarted(
    FriendProfileStarted event,
    Emitter<FriendProfileState> emit,
  ) async {
    _changesSubscription ??= _watchFriendshipChanges(const NoParams()).listen(
      (RelationshipEntity relationship) =>
          add(_FriendshipChanged(relationship)),
    );
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
    emit(
      FriendProfileState(
        friendId: event.friendId,
        relationshipId: event.relationshipId,
      ),
    );
    await _load(emit);
  }

  Future<void> _onRefresh(
    FriendProfileRefreshRequested event,
    Emitter<FriendProfileState> emit,
  ) => _load(emit);

  void _onReconnected(_Reconnected event, Emitter<FriendProfileState> emit) {
    if (stateValue.friendId != null && !stateValue.isNoLongerFriends) {
      add(const FriendProfileRefreshRequested());
    }
  }

  Future<void> _load(Emitter<FriendProfileState> emit) async {
    final String? friendId = stateValue.friendId;
    if (friendId == null || stateValue.isNoLongerFriends) return;
    final int version = ++_loadVersion;
    emit(stateValue.copyWith(loadStatus: LoadStatus.loading));
    final Either<Failure, FriendProfileEntity> result = await _getFriendProfile(
      FriendParamsEntity(friendId: friendId),
    );
    if (emit.isDone || version != _loadVersion || stateValue.isNoLongerFriends) {
      return;
    }
    result.match(
      (Failure failure) {
        if (failure.hasCode(ApiErrorCodes.friendNotFound)) {
          _clear(emit);
          return;
        }
        // A failed refetch keeps the profile on screen.
        emit(stateValue.copyWith(loadStatus: LoadStatus.failure, failure: failure));
      },
      (FriendProfileEntity profile) => emit(
        stateValue.copyWith(
          loadStatus: LoadStatus.success,
          profile: profile,
          resetFailure: true,
        ),
      ),
    );
  }

  void _onFriendshipChanged(
    _FriendshipChanged event,
    Emitter<FriendProfileState> emit,
  ) {
    final RelationshipEntity record = event.relationship;
    final String? friendId = stateValue.friendId;
    if (friendId == null || stateValue.isNoLongerFriends) return;
    if (record.otherPlayer.id != friendId) return;
    final String? relationshipId = stateValue.relationshipId;
    if (record.status == RelationshipStatus.removed &&
        relationshipId != null &&
        record.id == relationshipId) {
      _loadVersion++;
      _clear(emit);
      return;
    }
    if (record.status == RelationshipStatus.removed ||
        record.status == RelationshipStatus.accepted) {
      add(const FriendProfileRefreshRequested());
    }
  }

  Future<void> _onRemove(
    FriendProfileRemoveRequested event,
    Emitter<FriendProfileState> emit,
  ) async {
    final String? friendId = stateValue.friendId;
    if (friendId == null || stateValue.isNoLongerFriends) return;
    emit(
      stateValue.copyWith(
        removeStatus: LoadStatus.loading,
        resetRemoveFailure: true,
      ),
    );
    final Either<Failure, Unit> result = await _removeFriend(
      FriendParamsEntity(friendId: friendId),
    );
    if (emit.isDone) return;
    result.match(
      (Failure failure) => emit(
        stateValue.copyWith(
          removeStatus: LoadStatus.failure,
          removeFailure: failure,
        ),
      ),
      (_) {
        _loadVersion++;
        emit(stateValue.copyWith(removeStatus: LoadStatus.success));
        _clear(emit);
      },
    );
  }

  void _clear(Emitter<FriendProfileState> emit) => emit(
    stateValue.copyWith(
      loadStatus: LoadStatus.success,
      isNoLongerFriends: true,
      resetProfile: true,
      resetFailure: true,
    ),
  );

  @override
  Future<void> close() async {
    await _changesSubscription?.cancel();
    await _connectionSubscription?.cancel();
    return super.close();
  }
}
