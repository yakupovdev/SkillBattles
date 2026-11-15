import 'dart:async';

import 'package:skill_battles/core/data/repository/realtime_decode.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/error/failure_mapper.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/core/utils/realtime/realtime_client.dart';
import 'package:skill_battles/core/utils/realtime/realtime_envelope.dart';
import 'package:skill_battles/core/utils/session/auth_session.dart';
import 'package:skill_battles/core/utils/session/session_tokens.dart';
import 'package:skill_battles/core/utils/time/clock.dart';
import 'package:skill_battles/features/friends/data/models/duel_invitation_model.dart';
import 'package:skill_battles/features/friends/data/models/duel_invitations_snapshot_model.dart';
import 'package:skill_battles/features/friends/data/models/friend_code_model.dart';
import 'package:skill_battles/features/friends/data/models/friend_profile_model.dart';
import 'package:skill_battles/features/friends/data/models/friend_request_direction_model.dart';
import 'package:skill_battles/features/friends/data/models/friend_requests_page_model.dart';
import 'package:skill_battles/features/friends/data/models/friends_page_model.dart';
import 'package:skill_battles/features/friends/data/models/relationship_model.dart';
import 'package:skill_battles/features/friends/data/models/send_duel_invitation_request_model.dart';
import 'package:skill_battles/features/friends/data/models/send_friend_request_model.dart';
import 'package:skill_battles/features/friends/data/sources/remote/friends_remote.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitations_snapshot_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_code_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_profile_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_requests_page_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_requests_params_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friends_page_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friends_page_params_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/send_duel_invitation_params_entity.dart';
import 'package:skill_battles/features/friends/domain/repository/friends_repository.dart';

/// Remote, FRIENDSHIP_CHANGED and DUEL_INVITATION_CHANGED. Nothing is cached
/// (every endpoint is `Cache-Control: no-store`).
///
/// Records returned by this repository's own commands and single reads are
/// re-emitted into the watch streams next to the pushes, so the app-scope
/// inbox, the Friends screen and the room converge by id + version even
/// when a best-effort push is lost. The two controllers that carry them are
/// owned here and closed by [dispose] (the GetIt dispose callback).
///
/// The signed-in user's id resolves the direction of every record, so no
/// BLoC needs to know the user id.
final class FriendsRepositoryImpl implements FriendsRepository {
  FriendsRepositoryImpl({
    required this._remote,
    required this._realtime,
    required this._session,
    required this._clock,
  });

  final FriendsRemote _remote;
  final RealtimeClient _realtime;
  final AuthSession _session;
  final Clock _clock;

  final StreamController<RelationshipEntity> _ownRelationships =
      StreamController<RelationshipEntity>.broadcast();
  final StreamController<DuelInvitationEntity> _ownInvitations =
      StreamController<DuelInvitationEntity>.broadcast();

  String get _viewerId => _session.userId ?? '';

  @override
  Future<Either<Failure, FriendCodeEntity>> getFriendCode() async {
    try {
      final FriendCodeModel model = await _remote.getFriendCode();
      return Right(model.toEntity());
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, FriendsPageEntity>> getFriends(
    FriendsPageParamsEntity params,
  ) async {
    try {
      final FriendsPageModel model = await _remote.getFriends(
        page: params.page,
        size: params.size,
      );
      return Right(model.toEntity());
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, FriendProfileEntity>> getFriendProfile(
    String friendId,
  ) async {
    try {
      final FriendProfileModel model = await _remote.getFriendProfile(friendId);
      return Right(model.toEntity());
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeFriend(String friendId) async {
    try {
      await _remote.removeFriend(friendId);
      return const Right(unit);
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, RelationshipEntity>> sendFriendRequest(
    String friendCode,
  ) async {
    try {
      final RelationshipModel model = await _remote.sendFriendRequest(
        SendFriendRequestModel(friendCode: friendCode),
      );
      return Right(_emitRelationship(model));
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, FriendRequestsPageEntity>> getFriendRequests(
    FriendRequestsParamsEntity params,
  ) async {
    try {
      final FriendRequestsPageModel model = await _remote.getFriendRequests(
        direction: FriendRequestDirectionModel.fromEntity(params.direction),
        page: params.page,
        size: params.size,
      );
      return Right(model.toEntity(viewerId: _viewerId));
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, RelationshipEntity>> getFriendRequest(
    String requestId,
  ) async {
    try {
      final RelationshipModel model = await _remote.getFriendRequest(requestId);
      return Right(_emitRelationship(model));
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, RelationshipEntity>> acceptFriendRequest(
    String requestId,
  ) async {
    try {
      final RelationshipModel model = await _remote.acceptFriendRequest(
        requestId,
      );
      return Right(_emitRelationship(model));
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, RelationshipEntity>> declineFriendRequest(
    String requestId,
  ) async {
    try {
      final RelationshipModel model = await _remote.declineFriendRequest(
        requestId,
      );
      return Right(_emitRelationship(model));
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, Unit>> cancelFriendRequest(String requestId) async {
    try {
      await _remote.cancelFriendRequest(requestId);
      return const Right(unit);
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, DuelInvitationEntity>> sendDuelInvitation(
    SendDuelInvitationParamsEntity params,
  ) async {
    try {
      final DuelInvitationModel model = await _remote.sendDuelInvitation(
        params.duelId,
        SendDuelInvitationRequestModel.fromEntity(params),
      );
      return Right(_emitInvitation(model));
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, DuelInvitationsSnapshotEntity>> getRoomInvitations(
    String duelId,
  ) async {
    try {
      final DuelInvitationsSnapshotModel model = await _remote
          .getRoomInvitations(duelId);
      return Right(
        model.toEntity(viewerId: _viewerId, receivedAt: _clock.now()),
      );
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, DuelInvitationsSnapshotEntity>>
  getIncomingDuelInvitations() async {
    try {
      final DuelInvitationsSnapshotModel model = await _remote
          .getIncomingDuelInvitations();
      return Right(
        model.toEntity(viewerId: _viewerId, receivedAt: _clock.now()),
      );
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, DuelInvitationEntity>> getDuelInvitation(
    String invitationId,
  ) async {
    try {
      final DuelInvitationModel model = await _remote.getDuelInvitation(
        invitationId,
      );
      return Right(_emitInvitation(model));
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, DuelInvitationEntity>> acceptDuelInvitation(
    String invitationId,
  ) async {
    try {
      final DuelInvitationModel model = await _remote.acceptDuelInvitation(
        invitationId,
      );
      return Right(_emitInvitation(model));
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, DuelInvitationEntity>> declineDuelInvitation(
    String invitationId,
  ) async {
    try {
      final DuelInvitationModel model = await _remote.declineDuelInvitation(
        invitationId,
      );
      return Right(_emitInvitation(model));
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, Unit>> withdrawDuelInvitation(
    String invitationId,
  ) async {
    try {
      await _remote.withdrawDuelInvitation(invitationId);
      return const Right(unit);
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Stream<RelationshipEntity> watchFriendshipChanges() =>
      _merge<RelationshipEntity>(
        decodeRealtime<RelationshipEntity>(
          _realtime.events,
          type: RealtimeEventType.friendshipChanged,
          parse: (Map<String, dynamic> data) =>
              RelationshipModel.fromJson(data).toEntity(viewerId: _viewerId),
        ),
        _ownRelationships.stream,
      );

  @override
  Stream<DuelInvitationEntity> watchDuelInvitationChanges() =>
      _merge<DuelInvitationEntity>(
        decodeRealtime<DuelInvitationEntity>(
          _realtime.events,
          type: RealtimeEventType.duelInvitationChanged,
          parse: (Map<String, dynamic> data) =>
              DuelInvitationModel.fromJson(data).toEntity(viewerId: _viewerId),
        ),
        _ownInvitations.stream,
      );

  @override
  Stream<String?> watchSignedInUser() async* {
    yield _session.userId;
    yield* _session.changes.map((SessionTokens? tokens) => tokens?.userId);
  }

  /// Closes the controllers of own command results.
  Future<void> dispose() async {
    await _ownRelationships.close();
    await _ownInvitations.close();
  }

  RelationshipEntity _emitRelationship(RelationshipModel model) {
    final RelationshipEntity entity = model.toEntity(viewerId: _viewerId);
    if (!_ownRelationships.isClosed) _ownRelationships.add(entity);
    return entity;
  }

  DuelInvitationEntity _emitInvitation(DuelInvitationModel model) {
    final DuelInvitationEntity entity = model.toEntity(viewerId: _viewerId);
    if (!_ownInvitations.isClosed) _ownInvitations.add(entity);
    return entity;
  }

  /// Both sources in arrival order; subscribes to them only while listened.
  static Stream<T> _merge<T>(Stream<T> first, Stream<T> second) {
    final List<StreamSubscription<T>> subscriptions = <StreamSubscription<T>>[];
    late final StreamController<T> controller;
    controller = StreamController<T>(
      sync: true,
      onListen: () {
        for (final Stream<T> source in <Stream<T>>[first, second]) {
          subscriptions.add(
            source.listen(controller.add, onError: controller.addError),
          );
        }
      },
      onPause: () {
        for (final StreamSubscription<T> subscription in subscriptions) {
          subscription.pause();
        }
      },
      onResume: () {
        for (final StreamSubscription<T> subscription in subscriptions) {
          subscription.resume();
        }
      },
      onCancel: () async {
        await Future.wait<void>(
          subscriptions.map((StreamSubscription<T> s) => s.cancel()),
        );
        subscriptions.clear();
      },
    );
    return controller.stream;
  }
}
