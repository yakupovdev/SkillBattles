import 'package:jaspr/jaspr.dart';
import 'package:universal_web/js_interop.dart';
import 'package:universal_web/web.dart' as web;

import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/router/app_routes.dart';
import 'package:skill_battles/core/presentation/utils/reduced_motion.dart';

/// Ids of the page sections the top bar scrolls to.
abstract final class WelcomeAnchors {
  static const String top = 'welcome-top';
  static const String howItWorks = 'how-it-works';
  static const String features = 'features';
  static const String leagues = 'leagues';
}

/// Where the calls to action of the landing page lead.
extension WelcomeNavigation on BuildContext {
  /// The auth screen with the "Create account" tab selected.
  void goToSignUp() => goNamed(
    AppRoutes.auth.name,
    queryParameters: <String, String>{AppRoutes.authModeParam: AppRoutes.authModeSignUp},
  );

  /// The auth screen with the "Log in" tab selected.
  void goToLogIn() => goNamed(AppRoutes.auth.name);
}

/// Scrolls the section [id] into view (smoothly, or at once under reduced
/// motion) and moves the keyboard focus to it. The sticky top bar is cleared
/// by the section's `scroll-margin-top`.
void scrollToWelcomeSection(String id) {
  if (!kIsWeb) return;
  final web.Element? target = web.document.getElementById(id);
  if (target == null) return;
  target.scrollIntoView(
    web.ScrollIntoViewOptions(behavior: prefersReducedMotion() ? 'instant' : 'smooth', block: 'start'),
  );
  if (target.isA<web.HTMLElement>()) (target as web.HTMLElement).focus(web.FocusOptions(preventScroll: true));
}
