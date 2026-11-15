import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:skill_battles/app/config/app_config.dart';
import 'package:skill_battles/app/router/app_router.dart';
import 'package:skill_battles/core/data/repository/connection_repository_impl.dart';
import 'package:skill_battles/core/domain/repository/connection_repository.dart';
import 'package:skill_battles/core/domain/usecases/generate_id_usecase.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/utils/network/api_client.dart';
import 'package:skill_battles/core/utils/network/interceptors/auth_interceptor.dart';
import 'package:skill_battles/core/utils/network/interceptors/error_interceptor.dart';
import 'package:skill_battles/core/utils/realtime/realtime_client.dart';
import 'package:skill_battles/core/utils/session/auth_session.dart';
import 'package:skill_battles/core/utils/session/session_tokens.dart';
import 'package:skill_battles/core/utils/storage/token_storage.dart';
import 'package:skill_battles/core/utils/time/clock.dart';
import 'package:skill_battles/features/account/data/repository/account_repository_impl.dart';
import 'package:skill_battles/features/account/data/sources/remote/account_remote.dart';
import 'package:skill_battles/features/account/domain/repository/account_repository.dart';
import 'package:skill_battles/features/account/domain/usecases/get_account_state_usecase.dart';
import 'package:skill_battles/features/account/domain/usecases/get_activity_usecase.dart';
import 'package:skill_battles/features/account/domain/usecases/get_limits_usecase.dart';
import 'package:skill_battles/features/account/domain/usecases/get_me_usecase.dart';
import 'package:skill_battles/features/account/domain/usecases/get_season_history_usecase.dart';
import 'package:skill_battles/features/account/domain/usecases/get_statistics_usecase.dart';
import 'package:skill_battles/features/account/domain/usecases/update_profile_usecase.dart';
import 'package:skill_battles/features/account/domain/usecases/watch_account_changes_usecase.dart';
import 'package:skill_battles/features/auth/data/models/auth_response_model.dart';
import 'package:skill_battles/features/auth/data/repository/auth_repository_impl.dart';
import 'package:skill_battles/features/auth/data/sources/remote/auth_remote.dart';
import 'package:skill_battles/features/auth/domain/repository/auth_repository.dart';
import 'package:skill_battles/features/auth/domain/usecases/check_age_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/confirm_password_reset_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/is_signed_in_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/login_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/logout_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/register_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/request_password_reset_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/watch_signed_in_usecase.dart';
import 'package:skill_battles/features/battle/data/repository/battle_repository_impl.dart';
import 'package:skill_battles/features/battle/data/sources/remote/battle_remote.dart';
import 'package:skill_battles/features/battle/domain/repository/battle_repository.dart';
import 'package:skill_battles/features/battle/domain/usecases/get_battle_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/send_sticker_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/set_ready_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/submit_answer_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/surrender_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/watch_battle_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/watch_stickers_usecase.dart';
import 'package:skill_battles/features/battle_result/data/repository/battle_result_repository_impl.dart';
import 'package:skill_battles/features/battle_result/data/sources/remote/battle_result_remote.dart';
import 'package:skill_battles/features/battle_result/domain/repository/battle_result_repository.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/cancel_rematch_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/get_rematch_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/get_result_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/get_review_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/report_round_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/request_rematch_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/watch_rematch_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/watch_rematches_usecase.dart';
import 'package:skill_battles/features/catalog/data/repository/catalog_repository_impl.dart';
import 'package:skill_battles/features/catalog/data/sources/remote/catalog_remote.dart';
import 'package:skill_battles/features/catalog/domain/repository/catalog_repository.dart';
import 'package:skill_battles/features/catalog/domain/usecases/get_current_season_usecase.dart';
import 'package:skill_battles/features/catalog/domain/usecases/get_disciplines_usecase.dart';
import 'package:skill_battles/features/catalog/domain/usecases/get_ranks_usecase.dart';
import 'package:skill_battles/features/friends/data/repository/friends_repository_impl.dart';
import 'package:skill_battles/features/friends/data/sources/remote/friends_remote.dart';
import 'package:skill_battles/features/friends/domain/repository/friends_repository.dart';
import 'package:skill_battles/features/friends/domain/usecases/accept_duel_invitation_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/accept_friend_request_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/cancel_friend_request_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/decline_duel_invitation_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/decline_friend_request_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_duel_invitation_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friend_code_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friend_profile_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friend_request_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friend_requests_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friends_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_incoming_duel_invitations_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_room_invitations_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/remove_friend_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/send_duel_invitation_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/send_friend_request_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/watch_duel_invitation_changes_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/watch_friendship_changes_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/watch_signed_in_user_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/withdraw_duel_invitation_usecase.dart';
import 'package:skill_battles/features/history/data/repository/history_repository_impl.dart';
import 'package:skill_battles/features/history/data/sources/remote/history_remote.dart';
import 'package:skill_battles/features/history/domain/repository/history_repository.dart';
import 'package:skill_battles/features/history/domain/usecases/get_history_usecase.dart';
import 'package:skill_battles/features/leaderboard/data/repository/leaderboard_repository_impl.dart';
import 'package:skill_battles/features/leaderboard/data/sources/remote/leaderboard_remote.dart';
import 'package:skill_battles/features/leaderboard/domain/repository/leaderboard_repository.dart';
import 'package:skill_battles/features/leaderboard/domain/usecases/get_leaderboard_usecase.dart';
import 'package:skill_battles/features/matchmaking/data/repository/matchmaking_repository_impl.dart';
import 'package:skill_battles/features/matchmaking/data/sources/remote/matchmaking_remote.dart';
import 'package:skill_battles/features/matchmaking/domain/repository/matchmaking_repository.dart';
import 'package:skill_battles/features/matchmaking/domain/usecases/cancel_queue_entry_usecase.dart';
import 'package:skill_battles/features/matchmaking/domain/usecases/get_queue_entry_usecase.dart';
import 'package:skill_battles/features/matchmaking/domain/usecases/join_queue_usecase.dart';
import 'package:skill_battles/features/matchmaking/domain/usecases/watch_queue_entry_usecase.dart';
import 'package:skill_battles/features/private_duel/data/repository/private_duel_repository_impl.dart';
import 'package:skill_battles/features/private_duel/data/sources/remote/private_duel_remote.dart';
import 'package:skill_battles/features/private_duel/domain/repository/private_duel_repository.dart';
import 'package:skill_battles/features/private_duel/domain/usecases/cancel_duel_usecase.dart';
import 'package:skill_battles/features/private_duel/domain/usecases/create_duel_usecase.dart';
import 'package:skill_battles/features/private_duel/domain/usecases/get_duel_usecase.dart';
import 'package:skill_battles/features/private_duel/domain/usecases/join_duel_usecase.dart';
import 'package:skill_battles/features/private_duel/domain/usecases/watch_duel_usecase.dart';
import 'package:skill_battles/features/subscription/data/repository/subscription_repository_impl.dart';
import 'package:skill_battles/features/subscription/data/sources/remote/subscription_remote.dart';
import 'package:skill_battles/features/subscription/domain/repository/subscription_repository.dart';
import 'package:skill_battles/features/subscription/domain/usecases/get_plans_usecase.dart';
import 'package:skill_battles/features/subscription/domain/usecases/get_subscription_usecase.dart';
import 'package:skill_battles/features/subscription/domain/usecases/open_portal_usecase.dart';
import 'package:skill_battles/features/subscription/domain/usecases/start_checkout_usecase.dart';

/// The single composition root. Presentation resolves only use cases (and
/// `main` the router) through `AppDependenciesProvider.of(context)`.
final class AppDependencies {
  AppDependencies._(this._container, this.config);

  /// Wraps a container prepared elsewhere (tests).
  factory AppDependencies.fromContainer(
    GetIt container, {
    AppConfig config = const AppConfig(apiBaseUrl: '', eventsUrl: ''),
  }) => AppDependencies._(container, config);

  final GetIt _container;
  final AppConfig config;

  static Future<AppDependencies> init({AppConfig? config}) async {
    final AppDependencies dependencies = AppDependencies._(
      GetIt.asNewInstance(),
      config ?? AppConfig.fromEnvironment(),
    );
    dependencies._registerCore();
    dependencies._registerClients();
    dependencies._registerSources();
    dependencies._registerRepositories();
    dependencies._registerUsecases();
    dependencies._registerRouter();
    await dependencies._container.get<AuthSession>().restore();
    dependencies._container.get<RealtimeClient>().start();
    return dependencies;
  }

  T getDep<T extends Object>() => _container.get<T>();

  Future<void> dispose() => _container.reset();

  void _registerCore() {
    final GetIt c = _container;
    c.registerLazySingleton<Clock>(() => const SystemClock());
    c.registerLazySingleton<Uuid>(() => const Uuid());
    c.registerLazySingleton<TokenStorage>(
      () => const SecureTokenStorage(FlutterSecureStorage()),
    );
    c.registerLazySingleton<AuthSession>(
      () => AuthSession(
        storage: c.get<TokenStorage>(),
        refresher: _refreshTokens,
      ),
      dispose: (AuthSession session) => session.dispose(),
    );
  }

  /// Uses a client without the auth interceptor: the refresh token goes
  /// in its own `Authorization` header.
  Future<SessionTokens> _refreshTokens(String refreshToken) async {
    final AuthResponseModel model = await _container
        .get<AuthRemote>(instanceName: _refreshClient)
        .refresh(refreshToken);
    return model.toSessionTokens();
  }

  static const String _refreshClient = 'refresh';

  void _registerClients() {
    final GetIt c = _container;
    BaseOptions options() => BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    );
    c.registerLazySingleton<Dio>(() {
      final Dio dio = Dio(options());
      dio.interceptors.addAll(<Interceptor>[
        AuthInterceptor(session: c.get<AuthSession>(), dio: dio),
        const ErrorInterceptor(),
      ]);
      return dio;
    }, dispose: (Dio dio) => dio.close());
    c.registerLazySingleton<Dio>(
      () => Dio(options())..interceptors.add(const ErrorInterceptor()),
      instanceName: _refreshClient,
      dispose: (Dio dio) => dio.close(),
    );
    c.registerLazySingleton<ApiClient>(() => DioApiClient(c.get<Dio>()));
    c.registerLazySingleton<ApiClient>(
      () => DioApiClient(c.get<Dio>(instanceName: _refreshClient)),
      instanceName: _refreshClient,
    );
    c.registerLazySingleton<RealtimeClient>(
      () => StompRealtimeClient(
        session: c.get<AuthSession>(),
        url: config.eventsUrl,
      ),
      dispose: (RealtimeClient client) => client.dispose(),
    );
  }

  void _registerSources() {
    final GetIt c = _container;
    ApiClient api() => c.get<ApiClient>();
    c.registerLazySingleton<AuthRemote>(() => AuthRemoteImpl(api()));
    c.registerLazySingleton<AuthRemote>(
      () => AuthRemoteImpl(c.get<ApiClient>(instanceName: _refreshClient)),
      instanceName: _refreshClient,
    );
    c.registerLazySingleton<AccountRemote>(() => AccountRemoteImpl(api()));
    c.registerLazySingleton<CatalogRemote>(() => CatalogRemoteImpl(api()));
    c.registerLazySingleton<MatchmakingRemote>(
      () => MatchmakingRemoteImpl(api()),
    );
    c.registerLazySingleton<PrivateDuelRemote>(
      () => PrivateDuelRemoteImpl(api()),
    );
    c.registerLazySingleton<BattleRemote>(() => BattleRemoteImpl(api()));
    c.registerLazySingleton<BattleResultRemote>(
      () => BattleResultRemoteImpl(api()),
    );
    c.registerLazySingleton<FriendsRemote>(() => FriendsRemoteImpl(api()));
    c.registerLazySingleton<HistoryRemote>(() => HistoryRemoteImpl(api()));
    c.registerLazySingleton<LeaderboardRemote>(
      () => LeaderboardRemoteImpl(api()),
    );
    c.registerLazySingleton<SubscriptionRemote>(
      () => SubscriptionRemoteImpl(api()),
    );
  }

  void _registerRepositories() {
    final GetIt c = _container;
    c.registerLazySingleton<ConnectionRepository>(
      () => ConnectionRepositoryImpl(realtime: c.get<RealtimeClient>()),
    );
    c.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        remote: c.get<AuthRemote>(),
        session: c.get<AuthSession>(),
      ),
    );
    c.registerLazySingleton<AccountRepository>(
      () => AccountRepositoryImpl(
        remote: c.get<AccountRemote>(),
        subscriptionRemote: c.get<SubscriptionRemote>(),
        realtime: c.get<RealtimeClient>(),
        session: c.get<AuthSession>(),
      ),
    );
    c.registerLazySingleton<CatalogRepository>(
      () => CatalogRepositoryImpl(remote: c.get<CatalogRemote>()),
    );
    c.registerLazySingleton<MatchmakingRepository>(
      () => MatchmakingRepositoryImpl(
        remote: c.get<MatchmakingRemote>(),
        realtime: c.get<RealtimeClient>(),
      ),
    );
    c.registerLazySingleton<PrivateDuelRepository>(
      () => PrivateDuelRepositoryImpl(
        remote: c.get<PrivateDuelRemote>(),
        realtime: c.get<RealtimeClient>(),
      ),
    );
    c.registerLazySingleton<BattleRepository>(
      () => BattleRepositoryImpl(
        remote: c.get<BattleRemote>(),
        realtime: c.get<RealtimeClient>(),
        session: c.get<AuthSession>(),
        clock: c.get<Clock>(),
      ),
    );
    c.registerLazySingleton<BattleResultRepository>(
      () => BattleResultRepositoryImpl(
        remote: c.get<BattleResultRemote>(),
        realtime: c.get<RealtimeClient>(),
        session: c.get<AuthSession>(),
      ),
    );
    c.registerLazySingleton<FriendsRepository>(
      () => FriendsRepositoryImpl(
        remote: c.get<FriendsRemote>(),
        realtime: c.get<RealtimeClient>(),
        session: c.get<AuthSession>(),
        clock: c.get<Clock>(),
      ),
      dispose: (FriendsRepository repository) async {
        if (repository is FriendsRepositoryImpl) await repository.dispose();
      },
    );
    c.registerLazySingleton<HistoryRepository>(
      () => HistoryRepositoryImpl(remote: c.get<HistoryRemote>()),
    );
    c.registerLazySingleton<LeaderboardRepository>(
      () => LeaderboardRepositoryImpl(remote: c.get<LeaderboardRemote>()),
    );
    c.registerLazySingleton<SubscriptionRepository>(
      () => SubscriptionRepositoryImpl(remote: c.get<SubscriptionRemote>()),
    );
  }

  void _registerUsecases() {
    final GetIt c = _container;
    // Core.
    c.registerLazySingleton(() => GenerateIdUsecase(c.get<Uuid>()));
    c.registerLazySingleton(
      () => WatchConnectionUsecase(c.get<ConnectionRepository>()),
    );
    // Auth.
    c.registerLazySingleton(() => CheckAgeUsecase(c.get<Clock>()));
    c.registerLazySingleton(
      () => RegisterUsecase(
        repository: c.get<AuthRepository>(),
        checkAge: c.get<CheckAgeUsecase>(),
      ),
    );
    c.registerLazySingleton(() => LoginUsecase(c.get<AuthRepository>()));
    c.registerLazySingleton(() => LogoutUsecase(c.get<AuthRepository>()));
    c.registerLazySingleton(
      () => RequestPasswordResetUsecase(c.get<AuthRepository>()),
    );
    c.registerLazySingleton(
      () => ConfirmPasswordResetUsecase(c.get<AuthRepository>()),
    );
    c.registerLazySingleton(
      () => WatchSignedInUsecase(c.get<AuthRepository>()),
    );
    c.registerLazySingleton(() => IsSignedInUsecase(c.get<AuthRepository>()));
    // Account.
    c.registerLazySingleton(() => GetMeUsecase(c.get<AccountRepository>()));
    c.registerLazySingleton(
      () => GetStatisticsUsecase(c.get<AccountRepository>()),
    );
    c.registerLazySingleton(() => GetLimitsUsecase(c.get<AccountRepository>()));
    c.registerLazySingleton(
      () => GetActivityUsecase(c.get<AccountRepository>()),
    );
    c.registerLazySingleton(
      () => GetAccountStateUsecase(c.get<AccountRepository>()),
    );
    c.registerLazySingleton(
      () => GetSeasonHistoryUsecase(c.get<AccountRepository>()),
    );
    c.registerLazySingleton(
      () => UpdateProfileUsecase(c.get<AccountRepository>()),
    );
    c.registerLazySingleton(
      () => WatchAccountChangesUsecase(c.get<AccountRepository>()),
    );
    // Catalogue.
    c.registerLazySingleton(
      () => GetDisciplinesUsecase(c.get<CatalogRepository>()),
    );
    c.registerLazySingleton(() => GetRanksUsecase(c.get<CatalogRepository>()));
    c.registerLazySingleton(
      () => GetCurrentSeasonUsecase(c.get<CatalogRepository>()),
    );
    // Matchmaking.
    c.registerLazySingleton(
      () => JoinQueueUsecase(c.get<MatchmakingRepository>()),
    );
    c.registerLazySingleton(
      () => GetQueueEntryUsecase(c.get<MatchmakingRepository>()),
    );
    c.registerLazySingleton(
      () => CancelQueueEntryUsecase(c.get<MatchmakingRepository>()),
    );
    c.registerLazySingleton(
      () => WatchQueueEntryUsecase(c.get<MatchmakingRepository>()),
    );
    // Private duels.
    c.registerLazySingleton(
      () => CreateDuelUsecase(c.get<PrivateDuelRepository>()),
    );
    c.registerLazySingleton(
      () => JoinDuelUsecase(c.get<PrivateDuelRepository>()),
    );
    c.registerLazySingleton(
      () => GetDuelUsecase(c.get<PrivateDuelRepository>()),
    );
    c.registerLazySingleton(
      () => CancelDuelUsecase(c.get<PrivateDuelRepository>()),
    );
    c.registerLazySingleton(
      () => WatchDuelUsecase(c.get<PrivateDuelRepository>()),
    );
    // Live battle.
    c.registerLazySingleton(() => GetBattleUsecase(c.get<BattleRepository>()));
    c.registerLazySingleton(() => SetReadyUsecase(c.get<BattleRepository>()));
    c.registerLazySingleton(
      () => SubmitAnswerUsecase(c.get<BattleRepository>()),
    );
    c.registerLazySingleton(() => SurrenderUsecase(c.get<BattleRepository>()));
    c.registerLazySingleton(
      () => WatchBattleUsecase(c.get<BattleRepository>()),
    );
    c.registerLazySingleton(
      () => SendStickerUsecase(c.get<BattleRepository>()),
    );
    c.registerLazySingleton(
      () => WatchStickersUsecase(c.get<BattleRepository>()),
    );
    // Result, review, rematch, reports.
    c.registerLazySingleton(
      () => GetResultUsecase(c.get<BattleResultRepository>()),
    );
    c.registerLazySingleton(
      () => GetReviewUsecase(c.get<BattleResultRepository>()),
    );
    c.registerLazySingleton(
      () => GetRematchUsecase(c.get<BattleResultRepository>()),
    );
    c.registerLazySingleton(
      () => RequestRematchUsecase(c.get<BattleResultRepository>()),
    );
    c.registerLazySingleton(
      () => CancelRematchUsecase(c.get<BattleResultRepository>()),
    );
    c.registerLazySingleton(
      () => WatchRematchUsecase(c.get<BattleResultRepository>()),
    );
    c.registerLazySingleton(
      () => WatchRematchesUsecase(c.get<BattleResultRepository>()),
    );
    c.registerLazySingleton(
      () => ReportRoundUsecase(c.get<BattleResultRepository>()),
    );
    // Friends and room invitations.
    c.registerLazySingleton(
      () => AcceptDuelInvitationUsecase(c.get<FriendsRepository>()),
    );
    c.registerLazySingleton(
      () => AcceptFriendRequestUsecase(c.get<FriendsRepository>()),
    );
    c.registerLazySingleton(
      () => CancelFriendRequestUsecase(c.get<FriendsRepository>()),
    );
    c.registerLazySingleton(
      () => DeclineDuelInvitationUsecase(c.get<FriendsRepository>()),
    );
    c.registerLazySingleton(
      () => DeclineFriendRequestUsecase(c.get<FriendsRepository>()),
    );
    c.registerLazySingleton(
      () => GetDuelInvitationUsecase(c.get<FriendsRepository>()),
    );
    c.registerLazySingleton(
      () => GetFriendCodeUsecase(c.get<FriendsRepository>()),
    );
    c.registerLazySingleton(
      () => GetFriendProfileUsecase(c.get<FriendsRepository>()),
    );
    c.registerLazySingleton(
      () => GetFriendRequestUsecase(c.get<FriendsRepository>()),
    );
    c.registerLazySingleton(
      () => GetFriendRequestsUsecase(c.get<FriendsRepository>()),
    );
    c.registerLazySingleton(
      () => GetFriendsUsecase(c.get<FriendsRepository>()),
    );
    c.registerLazySingleton(
      () => GetIncomingDuelInvitationsUsecase(c.get<FriendsRepository>()),
    );
    c.registerLazySingleton(
      () => GetRoomInvitationsUsecase(c.get<FriendsRepository>()),
    );
    c.registerLazySingleton(
      () => RemoveFriendUsecase(c.get<FriendsRepository>()),
    );
    c.registerLazySingleton(
      () => SendDuelInvitationUsecase(c.get<FriendsRepository>()),
    );
    c.registerLazySingleton(
      () => SendFriendRequestUsecase(c.get<FriendsRepository>()),
    );
    c.registerLazySingleton(
      () => WatchDuelInvitationChangesUsecase(c.get<FriendsRepository>()),
    );
    c.registerLazySingleton(
      () => WatchFriendshipChangesUsecase(c.get<FriendsRepository>()),
    );
    c.registerLazySingleton(
      () => WatchSignedInUserUsecase(c.get<FriendsRepository>()),
    );
    c.registerLazySingleton(
      () => WithdrawDuelInvitationUsecase(c.get<FriendsRepository>()),
    );
    // History and leaderboard.
    c.registerLazySingleton(
      () => GetHistoryUsecase(c.get<HistoryRepository>()),
    );
    c.registerLazySingleton(
      () => GetLeaderboardUsecase(c.get<LeaderboardRepository>()),
    );
    // Subscription.
    c.registerLazySingleton(
      () => GetPlansUsecase(c.get<SubscriptionRepository>()),
    );
    c.registerLazySingleton(
      () => GetSubscriptionUsecase(c.get<SubscriptionRepository>()),
    );
    c.registerLazySingleton(
      () => StartCheckoutUsecase(c.get<SubscriptionRepository>()),
    );
    c.registerLazySingleton(
      () => OpenPortalUsecase(c.get<SubscriptionRepository>()),
    );
  }

  void _registerRouter() {
    _container.registerLazySingleton<GoRouter>(
      () => createAppRouter(session: _container.get<AuthSession>()),
      dispose: (GoRouter router) => router.dispose(),
    );
  }
}
