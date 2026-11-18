import 'dart:async';

import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:skill_battles/core/utils/session/auth_session.dart';
import 'package:skill_battles/core/utils/session/session_tokens.dart';
import 'package:skill_battles/core/utils/storage/token_storage.dart';

const SessionTokens _initial = SessionTokens(
  accessToken: 'a1',
  refreshToken: 'r1',
  userId: 'u1',
);

DioException _rejected(int status) {
  final RequestOptions options = RequestOptions(path: '/auth/refresh');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: status,
      data: <String, dynamic>{
        'code': 'UNAUTHORIZED',
        'message': 'Session expired.',
        'fieldErrors': <Object?>[],
        'resetsAt': null,
      },
    ),
  );
}

void main() {
  test('concurrent refreshes share one request (single flight)', () async {
    int calls = 0;
    final Completer<SessionTokens> pending = Completer<SessionTokens>();
    final AuthSession session = AuthSession(
      storage: MemoryTokenStorage(),
      refresher: (String refreshToken) {
        calls++;
        expect(refreshToken, 'r1');
        return pending.future;
      },
    );
    await session.signIn(_initial);

    final Future<bool> first = session.refresh();
    final Future<bool> second = session.refresh();
    pending.complete(
      const SessionTokens(accessToken: 'a2', refreshToken: 'r2', userId: 'u1'),
    );

    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(calls, 1);
    expect(session.accessToken, 'a2');
    session.dispose();
  });

  test('a rejected refresh signs out and emits null', () async {
    final AuthSession session = AuthSession(
      storage: MemoryTokenStorage(),
      refresher: (_) async => throw _rejected(401),
    );
    await session.signIn(_initial);
    final List<SessionTokens?> changes = <SessionTokens?>[];
    final StreamSubscription<SessionTokens?> sub = session.changes.listen(
      changes.add,
    );

    expect(await session.refresh(), isFalse);
    await Future<void>.delayed(Duration.zero);

    expect(session.isSignedIn, isFalse);
    expect(changes, <SessionTokens?>[null]);
    await sub.cancel();
    session.dispose();
  });

  test('an unreachable server keeps the session', () async {
    final AuthSession session = AuthSession(
      storage: MemoryTokenStorage(),
      refresher: (_) async => throw DioException(
        requestOptions: RequestOptions(path: '/auth/refresh'),
        type: DioExceptionType.connectionError,
      ),
    );
    await session.signIn(_initial);

    expect(await session.refresh(), isFalse);
    expect(session.isSignedIn, isTrue);
    session.dispose();
  });

  test('restore reads the stored pair', () async {
    final MemoryTokenStorage storage = MemoryTokenStorage();
    await storage.write(_initial);
    final AuthSession session = AuthSession(
      storage: storage,
      refresher: (_) async => _initial,
    );

    await session.restore();

    expect(session.status, SessionStatus.signedIn);
    expect(session.userId, 'u1');
    session.dispose();
  });
}
