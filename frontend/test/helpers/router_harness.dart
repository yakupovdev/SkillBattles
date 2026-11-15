import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/router/app_router.dart';
import 'package:skill_battles/app/skill_battles_app.dart';
import 'package:skill_battles/core/domain/entity/entitlements_entity.dart';
import 'package:skill_battles/core/domain/entity/plan_code.dart';
import 'package:skill_battles/core/domain/entity/season_entity.dart';
import 'package:skill_battles/core/domain/entity/subscription_entity.dart';
import 'package:skill_battles/core/domain/entity/subscription_status.dart';
import 'package:skill_battles/core/domain/entity/user_entity.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/core/utils/session/auth_session.dart';
import 'package:skill_battles/core/utils/session/session_tokens.dart';
import 'package:skill_battles/core/utils/storage/token_storage.dart';
import 'package:skill_battles/core/utils/time/clock.dart';
import 'package:skill_battles/features/account/domain/entity/account_state_entity.dart';
import 'package:skill_battles/features/account/domain/entity/activity_entity.dart';
import 'package:skill_battles/features/account/domain/entity/limits_entity.dart';
import 'package:skill_battles/features/account/domain/entity/statistics_entity.dart';
import 'package:skill_battles/features/account/domain/entity/streaks_entity.dart';
import 'package:skill_battles/features/account/domain/repository/account_repository.dart';
import 'package:skill_battles/features/auth/domain/usecases/check_age_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/register_usecase.dart';
import 'package:skill_battles/features/catalog/domain/entity/discipline_entity.dart';
import 'package:skill_battles/features/catalog/domain/entity/rank_ladder_entity.dart';
import 'package:skill_battles/features/catalog/domain/repository/catalog_repository.dart';
import 'package:skill_battles/features/private_duel/domain/repository/private_duel_repository.dart';
import 'package:skill_battles/features/private_duel/domain/usecases/join_duel_usecase.dart';
import 'package:skill_battles/features/account/domain/usecases/get_account_state_usecase.dart';
import 'package:skill_battles/features/account/domain/usecases/get_activity_usecase.dart';
import 'package:skill_battles/features/account/domain/usecases/get_statistics_usecase.dart';
import 'package:skill_battles/features/account/domain/usecases/watch_account_changes_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/is_signed_in_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/watch_signed_in_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/logout_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/login_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/watch_rematches_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/get_rematch_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/get_result_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/request_rematch_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/cancel_rematch_usecase.dart';
import 'package:skill_battles/features/catalog/domain/usecases/get_disciplines_usecase.dart';
import 'package:skill_battles/features/catalog/domain/usecases/get_ranks_usecase.dart';
import 'package:skill_battles/features/catalog/domain/usecases/get_current_season_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/watch_signed_in_user_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/watch_friendship_changes_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/watch_duel_invitation_changes_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friend_requests_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friend_request_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/accept_friend_request_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/decline_friend_request_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_incoming_duel_invitations_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_room_invitations_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_duel_invitation_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/accept_duel_invitation_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/decline_duel_invitation_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friend_code_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friends_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/send_friend_request_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/cancel_friend_request_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/remove_friend_usecase.dart';

import 'friends_fakes.dart';
import 'notification_fakes.dart';

/// Real app/router/route wrappers over isolated, controlled repositories.
/// Every dependency stays in memory; no production client or storage starts.
final class RouterHarness {
  RouterHarness._({
    required this.dependencies,
    required this.router,
    required this.session,
    required this.auth,
    required this.friends,
    required this.connection,
    required this.results,
  });

  final AppDependencies dependencies;
  final GoRouter router;
  final AuthSession session;
  final FakeAuthRepository auth;
  final ScriptedFriendsRepository friends;
  final FakeConnectionRepository connection;
  final FakeBattleResultRepository results;

  static Future<RouterHarness> create({
    bool signedIn = false,
    String? location,
    ScriptedFriendsRepository? friendsRepository,
  }) async {
    final GetIt container = GetIt.asNewInstance();
    final FakeAuthRepository auth = FakeAuthRepository(isSignedIn: signedIn);
    final ScriptedFriendsRepository friends =
        friendsRepository ?? ScriptedFriendsRepository();
    friends.currentUserId = signedIn ? testMeId : null;
    final FakeConnectionRepository connection = FakeConnectionRepository();
    final FakeBattleResultRepository results = FakeBattleResultRepository();
    final _AccountRepository account = _AccountRepository();
    final _CatalogRepository catalog = _CatalogRepository();
    final AuthSession session = AuthSession(
      storage: MemoryTokenStorage(),
      refresher: (_) async => _tokens,
    );
    if (signedIn) await session.signIn(_tokens);
    final CheckAgeUsecase checkAge = CheckAgeUsecase(_FixedClock());
    container.registerSingleton(checkAge);
    container.registerSingleton(
      RegisterUsecase(repository: auth, checkAge: checkAge),
    );
    container.registerSingleton(WatchConnectionUsecase(connection));
    container.registerSingleton(JoinDuelUsecase(_PrivateDuelRepository()));
    container.registerSingleton(GetAccountStateUsecase(account));
    container.registerSingleton(GetActivityUsecase(account));
    container.registerSingleton(GetStatisticsUsecase(account));
    container.registerSingleton(WatchAccountChangesUsecase(account));
    container.registerSingleton(IsSignedInUsecase(auth));
    container.registerSingleton(WatchSignedInUsecase(auth));
    container.registerSingleton(LogoutUsecase(auth));
    container.registerSingleton(LoginUsecase(auth));
    container.registerSingleton(WatchRematchesUsecase(results));
    container.registerSingleton(GetRematchUsecase(results));
    container.registerSingleton(GetResultUsecase(results));
    container.registerSingleton(RequestRematchUsecase(results));
    container.registerSingleton(CancelRematchUsecase(results));
    container.registerSingleton(GetDisciplinesUsecase(catalog));
    container.registerSingleton(GetRanksUsecase(catalog));
    container.registerSingleton(GetCurrentSeasonUsecase(catalog));
    container.registerSingleton(WatchSignedInUserUsecase(friends));
    container.registerSingleton(WatchFriendshipChangesUsecase(friends));
    container.registerSingleton(WatchDuelInvitationChangesUsecase(friends));
    container.registerSingleton(GetFriendRequestsUsecase(friends));
    container.registerSingleton(GetFriendRequestUsecase(friends));
    container.registerSingleton(AcceptFriendRequestUsecase(friends));
    container.registerSingleton(DeclineFriendRequestUsecase(friends));
    container.registerSingleton(GetIncomingDuelInvitationsUsecase(friends));
    container.registerSingleton(GetRoomInvitationsUsecase(friends));
    container.registerSingleton(GetDuelInvitationUsecase(friends));
    container.registerSingleton(AcceptDuelInvitationUsecase(friends));
    container.registerSingleton(DeclineDuelInvitationUsecase(friends));
    container.registerSingleton(GetFriendCodeUsecase(friends));
    container.registerSingleton(GetFriendsUsecase(friends));
    container.registerSingleton(SendFriendRequestUsecase(friends));
    container.registerSingleton(CancelFriendRequestUsecase(friends));
    container.registerSingleton(RemoveFriendUsecase(friends));
    final GoRouter router = createAppRouter(
      session: session,
      initialLocation: location,
    );
    container.registerSingleton(
      router,
      dispose: (GoRouter value) => value.dispose(),
    );
    return RouterHarness._(
      dependencies: AppDependencies.fromContainer(container),
      router: router,
      session: session,
      auth: auth,
      friends: friends,
      connection: connection,
      results: results,
    );
  }

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppDependenciesProvider(
        dependencies: dependencies,
        child: SkillBattlesApp(router: router),
      ),
    );
    await pumpFrames(tester);
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.runAsync(() async {
      await dependencies.dispose();
      await friends.dispose();
      await results.rematches.close();
      await auth.changes.close();
      await connection.changes.close();
      session.dispose();
    });
  }
}

Future<void> pumpFrames(WidgetTester tester, [int steps = 8]) async {
  for (int i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

const SessionTokens _tokens = SessionTokens(
  accessToken: 'test-access',
  refreshToken: 'test-refresh',
  userId: testMeId,
);

final class _FixedClock implements Clock {
  @override
  DateTime now() => DateTime.utc(2026, 11, 15, 12);
}

const EntitlementsEntity _entitlements = EntitlementsEntity(
  isPro: false,
  version: 1,
  unlimitedRanked: false,
  historyMatchLimit: 10,
  canViewCorrectAnswers: false,
  canViewExplanations: false,
  canViewAdvancedAnalytics: false,
  canFilterMistakes: false,
);

StreaksEntity _streaks() => StreaksEntity(
  dailyCurrent: 0,
  dailyBest: 0,
  lastQualifiedDate: null,
  weeklyCurrent: 0,
  weeklyBest: 0,
  currentWeekStart: DateTime.utc(2026, 11, 9),
  currentWeekActiveDays: 0,
  currentWeekTarget: 4,
);

final class _AccountRepository implements AccountRepository {
  @override
  Future<Either<Failure, ActivityEntity>> getActivity() async =>
      const Right(ActivityEntity.none);

  @override
  Stream<AccountStateEntity> watchAccountChanges() =>
      const Stream<AccountStateEntity>.empty();

  @override
  Future<Either<Failure, StatisticsEntity>> getStatistics() async => Right(
    StatisticsEntity(
      entitlements: _entitlements,
      streaks: _streaks(),
      disciplines: const [],
    ),
  );

  @override
  Future<Either<Failure, AccountStateEntity>> getAccountState() async => Right(
    AccountStateEntity(
      user: UserEntity(
        id: testMeId,
        email: 'tester@example.com',
        nickname: 'Tester',
        createdAt: DateTime.utc(2026),
        isPro: false,
      ),
      subscription: const SubscriptionEntity(
        planCode: PlanCode.free,
        status: SubscriptionStatus.none,
        isTestMode: true,
        currentPeriodStart: null,
        currentPeriodEnd: null,
        cancelAtPeriodEnd: false,
        entitlements: _entitlements,
      ),
      limits: LimitsEntity(
        planCode: PlanCode.free,
        date: DateTime.utc(2026, 11, 15),
        freeRankedLimit: 5,
        rankedStartedToday: 0,
        freeRankedRemaining: 5,
        resetsAt: DateTime.utc(2026, 11, 16, 5),
        canStartRanked: true,
        entitlements: _entitlements,
      ),
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

final class _CatalogRepository implements CatalogRepository {
  @override
  Future<Either<Failure, List<DisciplineEntity>>> getDisciplines() async =>
      Right(<DisciplineEntity>[
        _discipline('SAT_MATH', 'SAT Math'),
        _discipline('SAT_RW', 'SAT Reading & Writing'),
      ]);

  @override
  Future<Either<Failure, RankLadderEntity>> getRanks() async =>
      const Right(RankLadderEntity(tiers: []));

  @override
  Future<Either<Failure, SeasonEntity>> getCurrentSeason() async => Right(
    SeasonEntity(
      id: 'season-1',
      name: 'November 2026',
      startsAt: DateTime.utc(2026, 11),
      endsAt: DateTime.utc(2026, 12),
    ),
  );
}

DisciplineEntity _discipline(String code, String name) => DisciplineEntity(
  code: code,
  displayName: name,
  description: 'Test discipline',
  questionCount: 5,
  baseQuestionSeconds: 30,
  timings: const [],
  schedules: const [],
  overtimeSeconds: 15,
  readyTimeoutSeconds: 30,
  countdownSeconds: 3,
  revealSeconds: 3,
  reconnectGraceSeconds: 10,
  contentAvailable: true,
);

final class _PrivateDuelRepository implements PrivateDuelRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
