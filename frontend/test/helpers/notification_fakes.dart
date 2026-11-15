import 'dart:async';

import 'package:skill_battles/core/domain/entity/battle_mode.dart';
import 'package:skill_battles/core/domain/entity/battle_outcome.dart';
import 'package:skill_battles/core/domain/entity/battle_reason.dart';
import 'package:skill_battles/core/domain/entity/battle_result_entity.dart';
import 'package:skill_battles/core/domain/entity/battle_status.dart';
import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/core/domain/entity/result_player_entity.dart';
import 'package:skill_battles/core/domain/repository/connection_repository.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/account/domain/entity/activity_entity.dart';
import 'package:skill_battles/features/account/domain/repository/account_repository.dart';
import 'package:skill_battles/features/account/domain/usecases/get_activity_usecase.dart';
import 'package:skill_battles/features/auth/domain/repository/auth_repository.dart';
import 'package:skill_battles/features/auth/domain/usecases/watch_signed_in_usecase.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/entity/rematch_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/rematch_status.dart';
import 'package:skill_battles/features/battle_result/domain/repository/battle_result_repository.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/cancel_rematch_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/get_rematch_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/get_result_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/request_rematch_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/watch_rematches_usecase.dart';
import 'package:skill_battles/core/domain/entity/page_info_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitations_snapshot_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_requests_page_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_requests_params_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_entity.dart';
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

const String testMeId = 'me';
const String testOpponentId = 'opp';
const String testNickname = 'Rival';
const String testDiscipline = 'MATH';

/// Fixed "now" of the notification tests.
final DateTime testNow = DateTime.utc(2026, 11, 15, 12);

ApiFailure apiFailure(String code, {int status = 409}) =>
    ApiFailure(statusCode: status, errorCode: code, message: code);

ResultPlayerEntity _player(String id, String nickname) => ResultPlayerEntity(
  id: id,
  nickname: nickname,
  isPro: false,
  score: 0,
  correctCount: 0,
  ratingBefore: 0,
  ratingAfter: 0,
  ratingDelta: 0,
  kFactor: 0,
  rankBefore: 'BRONZE',
  rankAfter: 'BRONZE',
  calibrationMatchesRemaining: 0,
);

BattleResultEntity battleResult(String battleId, {String myUserId = testMeId}) {
  return BattleResultEntity(
    battleId: battleId,
    disciplineCode: testDiscipline,
    mode: BattleMode.private,
    seasonId: null,
    status: BattleStatus.finished,
    reason: BattleReason.normal,
    winnerUserId: null,
    myOutcome: BattleOutcome.draw,
    finishedAt: testNow,
    overtimePlayed: false,
    players: <ResultPlayerEntity>[
      _player(testMeId, 'Me'),
      _player(testOpponentId, testNickname),
    ],
    myUserId: myUserId,
  );
}

RematchEntity rematch(
  String sourceId, {
  RematchStatus status = RematchStatus.waiting,
  List<String> requestedBy = const <String>[testOpponentId],
  int version = 1,
  DateTime? expiresAt,
  String? battleId,
}) => RematchEntity(
  sourceBattleId: sourceId,
  status: status,
  requestedBy: requestedBy,
  expiresAt: expiresAt ?? testNow.add(const Duration(seconds: 60)),
  battleId: battleId,
  version: version,
);

const ActivityEntity busyActivity = ActivityEntity(
  type: ActivityType.battle,
  resourceId: 'x',
  battleId: 'x',
  resourceKind: ActivityResourceKind.battle,
);

final class FakeBattleResultRepository implements BattleResultRepository {
  final StreamController<RematchEntity> rematches =
      StreamController<RematchEntity>.broadcast();

  Future<Either<Failure, BattleResultEntity>> Function(String id) onGetResult =
      (String id) async => Right(battleResult(id));
  Future<Either<Failure, RematchEntity>> Function(String id) onRequest = (
    String id,
  ) async => Right(rematch(id));
  Future<Either<Failure, Unit>> Function(String id) onCancel = (
    String id,
  ) async => const Right(unit);
  Future<Either<Failure, RematchEntity?>> Function(String id) onGetRematch = (
    String id,
  ) async => const Right(null);

  final List<String> getResultCalls = <String>[];
  final List<String> requestCalls = <String>[];
  final List<String> cancelCalls = <String>[];
  final List<String> getRematchCalls = <String>[];

  @override
  Future<Either<Failure, BattleResultEntity>> getResult(String battleId) {
    getResultCalls.add(battleId);
    return onGetResult(battleId);
  }

  @override
  Future<Either<Failure, RematchEntity?>> getRematch(String battleId) {
    getRematchCalls.add(battleId);
    return onGetRematch(battleId);
  }

  @override
  Future<Either<Failure, RematchEntity>> requestRematch(String battleId) {
    requestCalls.add(battleId);
    return onRequest(battleId);
  }

  @override
  Future<Either<Failure, Unit>> cancelRematch(String battleId) {
    cancelCalls.add(battleId);
    return onCancel(battleId);
  }

  @override
  Stream<RematchEntity> watchRematches() => rematches.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

final class FakeAccountRepository implements AccountRepository {
  Future<Either<Failure, ActivityEntity>> Function() onGetActivity = () async =>
      const Right(ActivityEntity.none);
  int activityCalls = 0;

  @override
  Future<Either<Failure, ActivityEntity>> getActivity() {
    activityCalls++;
    return onGetActivity();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

final class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.isSignedIn = true});

  final StreamController<bool> changes = StreamController<bool>.broadcast();

  @override
  bool isSignedIn;

  @override
  Stream<bool> watchSignedIn() => changes.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

final class FakeConnectionRepository implements ConnectionRepository {
  FakeConnectionRepository({this.status = RealtimeStatus.connected});

  final StreamController<RealtimeStatus> changes =
      StreamController<RealtimeStatus>.broadcast();

  @override
  RealtimeStatus status;

  @override
  Stream<RealtimeStatus> watchStatus() => changes.stream;
}

/// Friends side of the notifications: empty lists by default, the user id
/// follows [FakeAuthRepository.changes], pushes through [friendships] and
/// [invitations]. Commands not configured throw.
final class FakeFriendsRepository implements FriendsRepository {
  FakeFriendsRepository(this._auth);

  final FakeAuthRepository _auth;

  final StreamController<RelationshipEntity> friendships =
      StreamController<RelationshipEntity>.broadcast();
  final StreamController<DuelInvitationEntity> invitations =
      StreamController<DuelInvitationEntity>.broadcast();

  static const PageInfoEntity _emptyPage = PageInfoEntity(
    page: 0,
    size: 20,
    totalElements: 0,
    totalPages: 0,
  );

  Future<Either<Failure, FriendRequestsPageEntity>> Function(
    FriendRequestsParamsEntity params,
  )
  onGetFriendRequests = (FriendRequestsParamsEntity params) async =>
      const Right(
        FriendRequestsPageEntity(
          items: <RelationshipEntity>[],
          page: _emptyPage,
        ),
      );
  Future<Either<Failure, DuelInvitationsSnapshotEntity>> Function()
  onGetIncomingDuelInvitations = () async => Right(
    DuelInvitationsSnapshotEntity(
      invitations: const <DuelInvitationEntity>[],
      serverTime: testNow,
      receivedAt: testNow,
    ),
  );

  int recoveryCalls = 0;

  @override
  Stream<String?> watchSignedInUser() async* {
    yield _auth.isSignedIn ? testMeId : null;
    yield* _auth.changes.stream.map(
      (bool signedIn) => signedIn ? testMeId : null,
    );
  }

  @override
  Stream<RelationshipEntity> watchFriendshipChanges() => friendships.stream;

  @override
  Stream<DuelInvitationEntity> watchDuelInvitationChanges() =>
      invitations.stream;

  @override
  Future<Either<Failure, FriendRequestsPageEntity>> getFriendRequests(
    FriendRequestsParamsEntity params,
  ) {
    recoveryCalls++;
    return onGetFriendRequests(params);
  }

  @override
  Future<Either<Failure, DuelInvitationsSnapshotEntity>>
  getIncomingDuelInvitations() => onGetIncomingDuelInvitations();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// A [NotificationBloc] over fakes with a controllable clock.
final class NotificationFixture {
  NotificationFixture({bool signedIn = true})
    : auth = FakeAuthRepository(isSignedIn: signedIn) {
    now = testNow;
    friends = FakeFriendsRepository(auth);
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
      watchSignedInUser: WatchSignedInUserUsecase(friends),
      watchFriendshipChanges: WatchFriendshipChangesUsecase(friends),
      watchDuelInvitationChanges: WatchDuelInvitationChangesUsecase(friends),
      getFriendRequests: GetFriendRequestsUsecase(friends),
      getFriendRequest: GetFriendRequestUsecase(friends),
      acceptFriendRequest: AcceptFriendRequestUsecase(friends),
      declineFriendRequest: DeclineFriendRequestUsecase(friends),
      getIncomingDuelInvitations: GetIncomingDuelInvitationsUsecase(friends),
      getRoomInvitations: GetRoomInvitationsUsecase(friends),
      getDuelInvitation: GetDuelInvitationUsecase(friends),
      acceptDuelInvitation: AcceptDuelInvitationUsecase(friends),
      declineDuelInvitation: DeclineDuelInvitationUsecase(friends),
      now: () => now,
    );
  }

  final FakeBattleResultRepository results = FakeBattleResultRepository();
  final FakeAccountRepository account = FakeAccountRepository();
  final FakeAuthRepository auth;
  final FakeConnectionRepository connection = FakeConnectionRepository();
  late final FakeFriendsRepository friends;
  late DateTime now;
  late final NotificationBloc bloc;

  NotificationState get state => bloc.state;

  /// Not awaited: under `testWidgets` the fake clock only moves on `pump`,
  /// so an awaited close would never complete in a tear-down.
  void dispose() {
    unawaited(bloc.close());
    unawaited(results.rematches.close());
    unawaited(auth.changes.close());
    unawaited(connection.changes.close());
    unawaited(friends.friendships.close());
    unawaited(friends.invitations.close());
  }
}
