import 'package:test/test.dart';

import 'package:skill_battles/app/router/app_router.dart';
import 'package:skill_battles/app/router/app_routes.dart';
import 'package:skill_battles/core/utils/session/auth_session.dart';
import 'package:skill_battles/core/utils/session/session_tokens.dart';
import 'package:skill_battles/core/utils/storage/token_storage.dart';

final class _MemoryStorage implements TokenStorage {
  @override
  Future<SessionTokens?> read() async => null;

  @override
  Future<void> write(SessionTokens tokens) async {}

  @override
  Future<void> clear() async {}
}

const SessionTokens _tokens = SessionTokens(
  accessToken: 'a',
  refreshToken: 'r',
  userId: 'u',
);

void main() {
  late AuthSession session;

  setUp(() {
    session = AuthSession(
      storage: _MemoryStorage(),
      refresher: (String _) async => _tokens,
    );
  });

  tearDown(() => session.dispose());

  group('signed out', () {
    for (final String path in <String>[
      '/',
      '/leaderboard',
      '/friends/x',
      '/battle/x',
      '/result/x',
      '/profile',
      '/play/search?discipline=SAT_MATH',
    ]) {
      test('$path redirects to the welcome page', () {
        expect(redirectFor(session, path), AppRoutes.welcome.path);
      });
    }

    for (final String path in <String>[
      '/welcome',
      '/welcome?utm=x',
      '/auth',
      '/auth/forgot',
      '/auth/reset',
      '/auth?mode=signup',
      '/auth/reset?token=x',
    ]) {
      test('$path stays', () {
        expect(redirectFor(session, path), isNull);
      });
    }
  });

  group('signed in', () {
    setUp(() => session.signIn(_tokens));

    for (final String path in <String>[
      '/welcome',
      '/welcome?x=1',
      '/auth',
      '/auth?mode=signup',
      '/auth/forgot',
    ]) {
      test('$path redirects home', () {
        expect(redirectFor(session, path), AppRoutes.home.path);
      });
    }

    for (final String path in <String>[
      '/auth/reset?token=x',
      '/',
      '/leaderboard',
      '/battle/x',
    ]) {
      test('$path stays', () {
        expect(redirectFor(session, path), isNull);
      });
    }

    // FeatureFlags.billing is a compile-time define, off by default.
    for (final String path in <String>[
      '/pro',
      '/billing/return?success=true',
    ]) {
      test('$path redirects home while billing is off', () {
        expect(redirectFor(session, path), AppRoutes.home.path);
      });
    }
  });
}
