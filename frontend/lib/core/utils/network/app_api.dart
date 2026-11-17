/// Every API path, header name and hand-written request key.
abstract final class AppApi {
  /// Set with `--dart-define=API_BASE_URL=...`.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '/api/v1',
  );

  /// STOMP 1.2 endpoint (native WebSocket), set with
  /// `--dart-define=EVENTS_URL=...`. Not under `/api/v1`.
  static const String eventsUrl = String.fromEnvironment(
    'EVENTS_URL',
    defaultValue: '/ws/v1/events',
  );

  /// Public origin that serves `/media/...` (question illustrations), set
  /// with `--dart-define=MEDIA_ORIGIN=https://host:port`. Empty on web means
  /// the page's own origin (the same-origin proxy); it is never derived from
  /// [baseUrl], which ends in `/api/v1`.
  static const String mediaOrigin = String.fromEnvironment(
    'MEDIA_ORIGIN',
    defaultValue: '',
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
  static const String directionKey = 'direction';

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

  // Friends and room invitations.
  static const String meFriendCode = '/users/me/friend-code';
  static const String meDuelInvitations = '/users/me/duel-invitations';
  static const String friends = '/friends';
  static String friend(String friendId) => '$friends/$friendId';
  static const String friendRequests = '/friend-requests';
  static String friendRequest(String id) => '$friendRequests/$id';
  static String friendRequestAccept(String id) => '$friendRequests/$id/accept';
  static String friendRequestDecline(String id) =>
      '$friendRequests/$id/decline';
  static String duelInvitations(String duelId) => '$duels/$duelId/invitations';
  static const String duelInvitationsRoot = '/duel-invitations';
  static String duelInvitation(String id) => '$duelInvitationsRoot/$id';
  static String duelInvitationAccept(String id) =>
      '$duelInvitationsRoot/$id/accept';
  static String duelInvitationDecline(String id) =>
      '$duelInvitationsRoot/$id/decline';

  // Battles.
  static String battle(String id) => '/battles/$id';
  static String battleReadiness(String id) => '/battles/$id/readiness';
  static String battleAnswers(String id) => '/battles/$id/answers';
  static String battleStickers(String id) => '/battles/$id/stickers';
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
