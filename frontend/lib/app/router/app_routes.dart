/// Every screen of the app. Use `AppRoutes.x.name` / `AppRoutes.x.path`;
/// never write a route path or name as a string literal.
enum AppRoutes {
  welcome('/welcome'),
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
  history('/history'),
  friends('/friends'),
  friendProfile('/friends/:$friendIdParam'),
  pro('/pro'),
  billingReturn('/billing/return');

  const AppRoutes(this.path);

  final String path;

  /// Path parameter of [battle] and [battleResult].
  static const String battleIdParam = 'battleId';

  /// Path parameter of [friendProfile]: the friend's user id.
  static const String friendIdParam = 'friendId';

  /// Query: discipline code (`SAT_MATH`) for [rankedSearch], [privateDuel]
  /// and [leaderboard].
  static const String disciplineParam = 'discipline';

  /// Query: queue entry to resume on [rankedSearch].
  static const String entryParam = 'entry';

  /// Query: code room to resume on [privateDuel].
  static const String duelParam = 'duel';

  /// Query of [auth]: the tab to open. [authModeSignUp] opens "Create
  /// account"; anything else (or no value) opens "Log in".
  static const String authModeParam = 'mode';

  /// Value of [authModeParam] that opens the "Create account" tab.
  static const String authModeSignUp = 'signup';

  /// Query: one-use reset token of [resetPassword]; removed from the
  /// address bar as soon as it is read.
  static const String tokenParam = 'token';

  /// Query set by the server-configured Stripe return URL on
  /// [billingReturn]. It never activates Pro by itself.
  static const String successParam = 'success';

  /// Routes reachable without a session.
  static const Set<AppRoutes> public = <AppRoutes>{
    welcome,
    auth,
    forgotPassword,
    resetPassword,
  };

  /// Roots of the top-bar tabs. `AppShell` keeps a visited root alive while
  /// another page is shown, so going back to its tab shows it as it was.
  static const Set<AppRoutes> tabRoots = <AppRoutes>{
    home,
    leaderboard,
    profile,
    history,
    friends,
  };
}
