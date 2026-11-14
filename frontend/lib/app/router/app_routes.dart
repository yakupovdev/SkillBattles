/// Every screen of the app. Use `AppRoutes.x.name` / `AppRoutes.x.path`;
/// never write a route path or name as a string literal.
enum AppRoutes {
  auth('/auth'),
  forgotPassword('/auth/forgot'),
  resetPassword('/auth/reset'),
  home('/'),
  rankedSearch('/play/search'),
  privateDuel('/play/duel'),
  battle('/battle/:$battleIdParam'),
  battleResult('/result/:$battleIdParam'),
  profile('/profile'),
  editProfile('/profile/edit'),
  leaderboard('/leaderboard'),
  pro('/pro'),
  billingReturn('/billing/return');

  const AppRoutes(this.path);

  final String path;

  /// Path parameter of [battle] and [battleResult].
  static const String battleIdParam = 'battleId';

  /// Query: discipline code (`SAT_MATH`) for [rankedSearch], [privateDuel]
  /// and [leaderboard].
  static const String disciplineParam = 'discipline';

  /// Query: queue entry to resume on [rankedSearch].
  static const String entryParam = 'entry';

  /// Query: code room to resume on [privateDuel].
  static const String duelParam = 'duel';

  /// Query: one-use reset token of [resetPassword]; removed from the
  /// address bar as soon as it is read.
  static const String tokenParam = 'token';

  /// Query set by the server-configured Stripe return URL on
  /// [billingReturn]. It never activates Pro by itself.
  static const String successParam = 'success';

  /// Routes reachable without a session.
  static const Set<AppRoutes> public = <AppRoutes>{
    auth,
    forgotPassword,
    resetPassword,
  };
}
