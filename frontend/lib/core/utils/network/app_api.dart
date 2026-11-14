/// Every API path, header name and hand-written request key.
abstract final class AppApi {
  /// Set with `--dart-define=API_BASE_URL=...`.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  /// STOMP 1.2 endpoint (native WebSocket), set with
  /// `--dart-define=EVENTS_URL=...`. Not under `/api/v1`.
  static const String eventsUrl = String.fromEnvironment(
    'EVENTS_URL',
    defaultValue: 'ws://localhost:8080/ws/v1/events',
  );

  /// The only subscription the server allows.
  static const String eventsDestination = '/user/queue/events';
  static const String eventsSubscriptionId = 'skillbattles-events';

  // Headers.
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer';
  static const String retryAfterHeader = 'retry-after';

  // Query keys.
  static const String pageKey = 'page';
  static const String sizeKey = 'size';
  static const String sortKey = 'sort';
  static const String disciplineCodeKey = 'disciplineCode';
  static const String modeKey = 'mode';
  static const String mistakesOnlyKey = 'mistakesOnly';

  // Authentication.
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String passwordResetRequest = '/auth/password-reset/request';
  static const String passwordResetConfirm = '/auth/password-reset/confirm';

  // Account and statistics.
  static const String me = '/users/me';
  static const String meStatistics = '/users/me/statistics';
  static const String meLimits = '/users/me/limits';
  static const String meActivity = '/users/me/activity';
  static const String meSeasons = '/users/me/seasons';
  static const String meBattles = '/users/me/battles';

  // Catalogue.
  static const String battleModes = '/battle-modes';
  static const String ranks = '/ranks';
  static const String currentSeason = '/seasons/current';

  // Matchmaking.
  static const String matchmakingEntries = '/matchmaking/entries';
  static String matchmakingEntry(String id) => '$matchmakingEntries/$id';

  // Private duels.
  static const String duels = '/duels';
  static const String duelsJoin = '/duels/join';
  static String duel(String id) => '$duels/$id';

  // Battles.
  static String battle(String id) => '/battles/$id';
  static String battleReadiness(String id) => '/battles/$id/readiness';
  static String battleAnswers(String id) => '/battles/$id/answers';
  static String battleSurrender(String id) => '/battles/$id/surrender';
  static String battleResult(String id) => '/battles/$id/result';
  static String battleReview(String id) => '/battles/$id/review';
  static String battleRematch(String id) => '/battles/$id/rematch';
  static String roundReport(String id, String roundId) =>
      '/battles/$id/rounds/$roundId/report';

  // Leaderboards.
  static String leaderboard(String disciplineCode) =>
      '/leaderboards/$disciplineCode';

  // Subscriptions and billing.
  static const String subscriptionPlans = '/subscriptions/plans';
  static const String subscriptionMe = '/subscriptions/me';
  static const String subscriptionCheckout = '/subscriptions/checkout';
  static const String subscriptionPortal = '/subscriptions/portal';
}
