import 'dart:async';

import 'package:uuid/uuid.dart';

import 'package:skill_battles/core/domain/entity/page_info_entity.dart';
import 'package:skill_battles/core/domain/entity/public_player_entity.dart';
import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/core/domain/usecases/generate_id_usecase.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/account/domain/usecases/get_activity_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/watch_signed_in_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/cancel_rematch_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/get_rematch_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/get_result_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/request_rematch_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/watch_rematches_usecase.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_reason.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_status.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitations_snapshot_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_code_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_list_item_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_profile_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_request_direction.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_requests_page_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_requests_params_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friends_page_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friends_page_params_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_status.dart';
import 'package:skill_battles/features/friends/domain/entity/send_duel_invitation_params_entity.dart';
import 'package:skill_battles/features/friends/domain/repository/friends_repository.dart';
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
import 'package:skill_battles/features/notifications/presentation/bloc/notification_bloc/notification_bloc.dart';

import 'notification_fakes.dart';

final DateTime friendsNow = DateTime.utc(2026, 11, 15, 12);

const PublicPlayerEntity friendAnna = PublicPlayerEntity(
  id: 'u-anna',
  nickname: 'Anna',
  isPro: false,
);
const PublicPlayerEntity friendBoris = PublicPlayerEntity(
  id: 'u-boris',
  nickname: 'Boris',
  isPro: true,
);
const PublicPlayerEntity mePlayer = PublicPlayerEntity(
  id: testMeId,
  nickname: 'Me',
  isPro: false,
);

/// Incoming by default (the other player is the requester).
RelationshipEntity relationship(
  String id, {
  RelationshipStatus status = RelationshipStatus.pending,
  int version = 1,
  bool incoming = true,
  PublicPlayerEntity other = friendAnna,
  DateTime? createdAt,
}) {
  return RelationshipEntity(
    id: id,
    requester: incoming ? other : mePlayer,
    recipient: incoming ? mePlayer : other,
    status: status,
    createdAt: createdAt ?? friendsNow,
    updatedAt: friendsNow,
    acceptedAt: status == RelationshipStatus.accepted ? friendsNow : null,
    version: version,
    direction: incoming
        ? FriendRequestDirection.incoming
        : FriendRequestDirection.outgoing,
  );
}

/// Incoming by default; expires 60 s after [friendsNow] (server clock).
DuelInvitationEntity invitation(
  String id, {
  DuelInvitationStatus status = DuelInvitationStatus.pending,
  DuelInvitationReason? reason,
  int version = 1,
  bool incoming = true,
  String duelId = 'duel-1',
  PublicPlayerEntity other = friendAnna,
  DateTime? expiresAt,
  DateTime? createdAt,
  String? battleId,
}) {
  return DuelInvitationEntity(
    id: id,
    duelId: duelId,
    host: incoming ? other : mePlayer,
    recipient: incoming ? mePlayer : other,
    disciplineCode: 'MATH',
    status: status,
    reason: reason,
    createdAt: createdAt ?? friendsNow,
    expiresAt: expiresAt ?? friendsNow.add(const Duration(seconds: 60)),
    battleId: battleId,
    version: version,
    isIncoming: incoming,
  );
}

PageInfoEntity pageInfo({
  int page = 0,
  int size = 20,
  int totalElements = 0,
  int totalPages = 0,
}) => PageInfoEntity(
  page: page,
  size: size,
  totalElements: totalElements,
  totalPages: totalPages,
);

FriendListItemEntity friendItem(
  String relationshipId,
  PublicPlayerEntity friend, {
  int version = 1,
}) => FriendListItemEntity(
  relationshipId: relationshipId,
  friend: friend,
  friendsSince: friendsNow,
  version: version,
);

FriendsPageEntity friendsPage(
  List<FriendListItemEntity> items, {
  int page = 0,
  int totalPages = 1,
  int? totalElements,
}) => FriendsPageEntity(
  items: items,
  page: pageInfo(
    page: page,
    totalPages: totalPages,
    totalElements: totalElements ?? items.length,
  ),
);

FriendRequestsPageEntity requestsPage(
  List<RelationshipEntity> items, {
  int page = 0,
  int totalPages = 1,
  int? totalElements,
}) => FriendRequestsPageEntity(
  items: items,
  page: pageInfo(
    page: page,
    totalPages: totalPages,
    totalElements: totalElements ?? items.length,
  ),
);

DuelInvitationsSnapshotEntity snapshot(
  List<DuelInvitationEntity> items, {
  Duration serverAhead = Duration.zero,
}) => DuelInvitationsSnapshotEntity(
  invitations: items,
  serverTime: friendsNow.add(serverAhead),
  receivedAt: friendsNow,
);

FriendProfileEntity profileOf(PublicPlayerEntity friend) => FriendProfileEntity(
  friend: friend,
  friendsSince: friendsNow,
  disciplines: const [],
);

Either<Failure, T> ok<T>(T value) => Right<Failure, T>(value);

Either<Failure, T> failed<T>(Failure failure) => Left<Failure, T>(failure);

/// Deterministic [GenerateIdUsecase]: `id-1`, `id-2`, ...
GenerateIdUsecase sequentialIds() => GenerateIdUsecase(_SequentialUuid());

final class _SequentialUuid extends Uuid {
  _SequentialUuid();

  int _next = 0;

  @override
  String v4({Map<String, dynamic>? options, Object? config}) => 'id-${++_next}';
}

/// Fully scriptable [FriendsRepository]. Every command has a callback, a
/// call log and sane empty defaults; pushes go through [friendships] and
/// [invitations], the signed-in user through [userIds].
final class ScriptedFriendsRepository implements FriendsRepository {
  final StreamController<RelationshipEntity> friendships =
      StreamController<RelationshipEntity>.broadcast();
  final StreamController<DuelInvitationEntity> invitations =
      StreamController<DuelInvitationEntity>.broadcast();
  final StreamController<String?> userIds =
      StreamController<String?>.broadcast();

  String? currentUserId = testMeId;

  Future<Either<Failure, FriendCodeEntity>> Function() onGetFriendCode =
      () async => ok(const FriendCodeEntity(code: 'ABCD2345EFGH'));
  Future<Either<Failure, FriendsPageEntity>> Function(
    FriendsPageParamsEntity params,
  )
  onGetFriends = (FriendsPageParamsEntity p) async =>
      ok(friendsPage(const <FriendListItemEntity>[], totalPages: 0));
  Future<Either<Failure, FriendProfileEntity>> Function(String friendId)
  onGetFriendProfile = (String id) async => ok(profileOf(friendAnna));
  Future<Either<Failure, Unit>> Function(String friendId) onRemoveFriend = (
    String id,
  ) async => ok(unit);
  Future<Either<Failure, RelationshipEntity>> Function(String code)
  onSendFriendRequest = (String code) async => ok(relationship('sent'));
  Future<Either<Failure, FriendRequestsPageEntity>> Function(
    FriendRequestsParamsEntity params,
  )
  onGetFriendRequests = (FriendRequestsParamsEntity p) async =>
      ok(requestsPage(const <RelationshipEntity>[], totalPages: 0));
  Future<Either<Failure, RelationshipEntity>> Function(String id)
  onGetFriendRequest = (String id) async =>
      failed(const UnexpectedFailure('unconfigured'));
  Future<Either<Failure, RelationshipEntity>> Function(String id)
  onAcceptFriendRequest = (String id) async =>
      failed(const UnexpectedFailure('unconfigured'));
  Future<Either<Failure, RelationshipEntity>> Function(String id)
  onDeclineFriendRequest = (String id) async =>
      failed(const UnexpectedFailure('unconfigured'));
  Future<Either<Failure, Unit>> Function(String id) onCancelFriendRequest = (
    String id,
  ) async => ok(unit);
  Future<Either<Failure, DuelInvitationEntity>> Function(
    SendDuelInvitationParamsEntity params,
  )
  onSendDuelInvitation = (SendDuelInvitationParamsEntity p) async =>
      failed(const UnexpectedFailure('unconfigured'));
  Future<Either<Failure, DuelInvitationsSnapshotEntity>> Function(String duelId)
  onGetRoomInvitations = (String id) async =>
      ok(snapshot(const <DuelInvitationEntity>[]));
  Future<Either<Failure, DuelInvitationsSnapshotEntity>> Function()
  onGetIncomingDuelInvitations = () async =>
      ok(snapshot(const <DuelInvitationEntity>[]));
  Future<Either<Failure, DuelInvitationEntity>> Function(String id)
  onGetDuelInvitation = (String id) async =>
      failed(const UnexpectedFailure('unconfigured'));
  Future<Either<Failure, DuelInvitationEntity>> Function(String id)
  onAcceptDuelInvitation = (String id) async =>
      failed(const UnexpectedFailure('unconfigured'));
  Future<Either<Failure, DuelInvitationEntity>> Function(String id)
  onDeclineDuelInvitation = (String id) async =>
      failed(const UnexpectedFailure('unconfigured'));
  Future<Either<Failure, Unit>> Function(String id) onWithdrawDuelInvitation = (
    String id,
  ) async => ok(unit);

  final List<FriendsPageParamsEntity> friendsCalls =
      <FriendsPageParamsEntity>[];
  final List<FriendRequestsParamsEntity> requestsCalls =
      <FriendRequestsParamsEntity>[];
  final List<String> sendCodes = <String>[];
  final List<String> acceptRequestCalls = <String>[];
  final List<String> declineRequestCalls = <String>[];
  final List<String> cancelRequestCalls = <String>[];
  final List<String> getRequestCalls = <String>[];
  final List<String> removeCalls = <String>[];
  final List<String> profileCalls = <String>[];
  final List<SendDuelInvitationParamsEntity> sendInvitationCalls =
      <SendDuelInvitationParamsEntity>[];
  final List<String> roomCalls = <String>[];
  final List<String> getInvitationCalls = <String>[];
  final List<String> acceptInvitationCalls = <String>[];
  final List<String> declineInvitationCalls = <String>[];
  final List<String> withdrawCalls = <String>[];
  int incomingInvitationCalls = 0;
  int codeCalls = 0;

  @override
  Stream<String?> watchSignedInUser() async* {
    yield currentUserId;
    yield* userIds.stream;
  }

  @override
  Stream<RelationshipEntity> watchFriendshipChanges() => friendships.stream;

  @override
  Stream<DuelInvitationEntity> watchDuelInvitationChanges() =>
      invitations.stream;

  @override
  Future<Either<Failure, FriendCodeEntity>> getFriendCode() {
    codeCalls++;
    return onGetFriendCode();
  }

  @override
  Future<Either<Failure, FriendsPageEntity>> getFriends(
    FriendsPageParamsEntity params,
  ) {
    friendsCalls.add(params);
    return onGetFriends(params);
  }

  @override
  Future<Either<Failure, FriendProfileEntity>> getFriendProfile(
    String friendId,
  ) {
    profileCalls.add(friendId);
    return onGetFriendProfile(friendId);
  }

  @override
  Future<Either<Failure, Unit>> removeFriend(String friendId) {
    removeCalls.add(friendId);
    return onRemoveFriend(friendId);
  }

  @override
  Future<Either<Failure, RelationshipEntity>> sendFriendRequest(
    String friendCode,
  ) {
    sendCodes.add(friendCode);
    return onSendFriendRequest(friendCode);
  }

  @override
  Future<Either<Failure, FriendRequestsPageEntity>> getFriendRequests(
    FriendRequestsParamsEntity params,
  ) {
    requestsCalls.add(params);
    return onGetFriendRequests(params);
  }

  @override
  Future<Either<Failure, RelationshipEntity>> getFriendRequest(
    String requestId,
  ) {
    getRequestCalls.add(requestId);
    return onGetFriendRequest(requestId);
  }

  @override
  Future<Either<Failure, RelationshipEntity>> acceptFriendRequest(
    String requestId,
  ) {
    acceptRequestCalls.add(requestId);
    return onAcceptFriendRequest(requestId);
  }

  @override
  Future<Either<Failure, RelationshipEntity>> declineFriendRequest(
    String requestId,
  ) {
    declineRequestCalls.add(requestId);
    return onDeclineFriendRequest(requestId);
  }

  @override
  Future<Either<Failure, Unit>> cancelFriendRequest(String requestId) {
    cancelRequestCalls.add(requestId);
    return onCancelFriendRequest(requestId);
  }

  @override
  Future<Either<Failure, DuelInvitationEntity>> sendDuelInvitation(
    SendDuelInvitationParamsEntity params,
  ) {
    sendInvitationCalls.add(params);
    return onSendDuelInvitation(params);
  }

  @override
  Future<Either<Failure, DuelInvitationsSnapshotEntity>> getRoomInvitations(
    String duelId,
  ) {
    roomCalls.add(duelId);
    return onGetRoomInvitations(duelId);
  }

  @override
  Future<Either<Failure, DuelInvitationsSnapshotEntity>>
  getIncomingDuelInvitations() {
    incomingInvitationCalls++;
    return onGetIncomingDuelInvitations();
  }

  @override
  Future<Either<Failure, DuelInvitationEntity>> getDuelInvitation(
    String invitationId,
  ) {
    getInvitationCalls.add(invitationId);
    return onGetDuelInvitation(invitationId);
  }

  @override
  Future<Either<Failure, DuelInvitationEntity>> acceptDuelInvitation(
    String invitationId,
  ) {
    acceptInvitationCalls.add(invitationId);
    return onAcceptDuelInvitation(invitationId);
  }

  @override
  Future<Either<Failure, DuelInvitationEntity>> declineDuelInvitation(
    String invitationId,
  ) {
    declineInvitationCalls.add(invitationId);
    return onDeclineDuelInvitation(invitationId);
  }

  @override
  Future<Either<Failure, Unit>> withdrawDuelInvitation(String invitationId) {
    withdrawCalls.add(invitationId);
    return onWithdrawDuelInvitation(invitationId);
  }

  Future<void> dispose() async {
    await friendships.close();
    await invitations.close();
    await userIds.close();
  }
}

/// A [NotificationBloc] whose friends side is a [ScriptedFriendsRepository].
final class FriendsNotificationFixture {
  FriendsNotificationFixture({bool signedIn = true})
    : auth = FakeAuthRepository(isSignedIn: signedIn) {
    now = friendsNow;
    bloc = NotificationBloc(
      watchRematches: WatchRematchesUsecase(results),
      getRematch: GetRematchUsecase(results),
      getResult: GetResultUsecase(results),
      requestRematch: RequestRematchUsecase(results),
      cancelRematch: CancelRematchUsecase(results),
      getActivity: GetActivityUsecase(account),
      watchSignedIn: WatchSignedInUsecase(auth),
      watchConnection: WatchConnectionUsecase(connection),
      isSignedIn: signedIn,
      watchSignedInUser: WatchSignedInUserUsecase(repo),
      watchFriendshipChanges: WatchFriendshipChangesUsecase(repo),
      watchDuelInvitationChanges: WatchDuelInvitationChangesUsecase(repo),
      getFriendRequests: GetFriendRequestsUsecase(repo),
      getFriendRequest: GetFriendRequestUsecase(repo),
      acceptFriendRequest: AcceptFriendRequestUsecase(repo),
      declineFriendRequest: DeclineFriendRequestUsecase(repo),
      getIncomingDuelInvitations: GetIncomingDuelInvitationsUsecase(repo),
      getRoomInvitations: GetRoomInvitationsUsecase(repo),
      getDuelInvitation: GetDuelInvitationUsecase(repo),
      acceptDuelInvitation: AcceptDuelInvitationUsecase(repo),
      declineDuelInvitation: DeclineDuelInvitationUsecase(repo),
      now: () => now,
    );
  }

  final FakeBattleResultRepository results = FakeBattleResultRepository();
  final FakeAccountRepository account = FakeAccountRepository();
  final FakeAuthRepository auth;
  final FakeConnectionRepository connection = FakeConnectionRepository();
  final ScriptedFriendsRepository repo = ScriptedFriendsRepository();
  late DateTime now;
  late final NotificationBloc bloc;

  NotificationState get state => bloc.state;

  /// Disconnect and connect again: triggers a baseline recovery.
  void reconnect() {
    connection.changes
      ..add(RealtimeStatus.disconnected)
      ..add(RealtimeStatus.connected);
  }

  /// Not awaited: under `testWidgets` the fake clock only moves on `pump`.
  void dispose() {
    unawaited(bloc.close());
    unawaited(results.rematches.close());
    unawaited(auth.changes.close());
    unawaited(connection.changes.close());
    unawaited(repo.dispose());
  }
}
