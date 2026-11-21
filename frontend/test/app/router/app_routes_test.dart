import 'package:test/test.dart';

import 'package:skill_battles/app/router/app_routes.dart';

void main() {
  group('AppRoutes welcome', () {
    test('has the /welcome path and name', () {
      expect(AppRoutes.welcome.path, '/welcome');
      expect(AppRoutes.welcome.name, 'welcome');
    });

    test('is public and not a tab root', () {
      expect(AppRoutes.public, contains(AppRoutes.welcome));
      expect(AppRoutes.tabRoots, isNot(contains(AppRoutes.welcome)));
    });

    test('public routes are exactly welcome and the auth routes', () {
      expect(AppRoutes.public, <AppRoutes>{
        AppRoutes.welcome,
        AppRoutes.auth,
        AppRoutes.forgotPassword,
        AppRoutes.resetPassword,
      });
    });

    test('auth mode query constants', () {
      expect(AppRoutes.authModeParam, 'mode');
      expect(AppRoutes.authModeSignUp, 'signup');
    });
  });
}
