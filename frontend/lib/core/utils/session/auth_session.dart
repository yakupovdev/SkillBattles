import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/error/failure_mapper.dart';
import 'package:skill_battles/core/utils/session/session_tokens.dart';
import 'package:skill_battles/core/utils/storage/token_storage.dart';

/// Rotates the pair with `POST /auth/refresh` (refresh token in
/// `Authorization`). Throws like a remote source.
typedef TokenRefresher = Future<SessionTokens> Function(String refreshToken);

/// Whether an account is signed in on this device.
enum SessionStatus { signedOut, signedIn }

/// Owner of the token pair: restore at launch, sign in/out, and the
/// single-flight refresh shared by every HTTP request and the socket.
///
/// The router listens to it (a [ChangeNotifier]) to redirect; the realtime
/// client listens to [changes] to reconnect with a new access token.
final class AuthSession extends ChangeNotifier {
  AuthSession({required this._storage, required this._refresher});

  final TokenStorage _storage;
  final TokenRefresher _refresher;
  final StreamController<SessionTokens?> _changes =
      StreamController<SessionTokens?>.broadcast();

  SessionTokens? _tokens;
  Future<bool>? _refreshing;

  SessionStatus get status =>
      _tokens == null ? SessionStatus.signedOut : SessionStatus.signedIn;

  bool get isSignedIn => _tokens != null;
  String? get accessToken => _tokens?.accessToken;
  String? get userId => _tokens?.userId;

  /// The refresh token, for `POST /auth/logout`.
  Future<String?> currentRefreshToken() async => _tokens?.refreshToken;

  /// Emits the new pair after sign-in and every refresh, `null` on sign-out.
  Stream<SessionTokens?> get changes => _changes.stream;

  /// Reads a pair stored by a previous launch. A storage failure signs out.
  Future<void> restore() async {
    try {
      _tokens = await _storage.read();
    } on Exception catch (error, stackTrace) {
      developer.log(
        'Session restore failed',
        name: 'auth_session',
        error: error.runtimeType,
        stackTrace: stackTrace,
      );
      _tokens = null;
    }
    notifyListeners();
  }

  Future<void> signIn(SessionTokens tokens) async {
    _tokens = tokens;
    await _persist(tokens);
    _changes.add(tokens);
    notifyListeners();
  }

  /// Forgets the pair locally (the caller revokes it on the server first
  /// when it can). Also clears paid data cached in memory by listeners.
  Future<void> signOut() async {
    if (_tokens == null) return;
    _tokens = null;
    try {
      await _storage.clear();
    } on Exception catch (error) {
      developer.log(
        'Token clear failed',
        name: 'auth_session',
        error: error.runtimeType,
      );
    }
    _changes.add(null);
    notifyListeners();
  }

  /// Rotates the pair once even when many requests ask at the same time.
  /// Returns whether a fresh access token is available. A rejected refresh
  /// (401, replay, expiry) signs out; an unreachable server keeps the pair.
  Future<bool> refresh() => _refreshing ??= _refresh().whenComplete(() {
    _refreshing = null;
  });

  Future<bool> _refresh() async {
    final SessionTokens? current = _tokens;
    if (current == null) return false;
    try {
      final SessionTokens next = await _refresher(current.refreshToken);
      // Signed out while waiting: drop the result.
      if (_tokens == null) return false;
      _tokens = next;
      await _persist(next);
      _changes.add(next);
      return true;
    } on Exception catch (exception, stackTrace) {
      final Failure failure = mapExceptionToFailure(exception, stackTrace);
      if (failure is ApiFailure && failure.statusCode < 500) {
        await signOut();
      }
      return false;
    }
  }

  Future<void> _persist(SessionTokens tokens) async {
    try {
      await _storage.write(tokens);
    } on Exception catch (error) {
      // The session still works for this launch.
      developer.log(
        'Token write failed',
        name: 'auth_session',
        error: error.runtimeType,
      );
    }
  }

  @override
  void dispose() {
    _changes.close();
    super.dispose();
  }
}
