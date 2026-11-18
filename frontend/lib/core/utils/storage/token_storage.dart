import 'package:universal_web/web.dart' as web;

import 'package:skill_battles/core/utils/error/app_exception.dart';
import 'package:skill_battles/core/utils/session/session_tokens.dart';
import 'package:skill_battles/core/utils/storage/storage_keys.dart';

/// Persists the token pair between launches. Tokens never go to logs,
/// URLs or cookies.
abstract interface class TokenStorage {
  /// `null` when no complete pair is stored.
  Future<SessionTokens?> read();

  Future<void> write(SessionTokens tokens);

  Future<void> clear();
}

/// Keeps the pair in the browser's `localStorage`, the same place
/// `flutter_secure_storage` used on web. Tokens never go to cookies, so
/// requests carry them only through the `Authorization` header.
final class BrowserTokenStorage implements TokenStorage {
  const BrowserTokenStorage(this._storage);

  final web.Storage _storage;

  @override
  Future<SessionTokens?> read() async {
    try {
      final String? access = _storage.getItem(StorageKeys.accessToken);
      final String? refresh = _storage.getItem(StorageKeys.refreshToken);
      final String? userId = _storage.getItem(StorageKeys.userId);
      if (access == null || refresh == null || userId == null) return null;
      return SessionTokens(
        accessToken: access,
        refreshToken: refresh,
        userId: userId,
      );
    } on Object catch (error) {
      // A blocked storage (private mode, disabled site data) throws a
      // `DOMException`, which is not an `Exception` in Dart.
      throw StorageException('Token read failed: ${error.runtimeType}');
    }
  }

  @override
  Future<void> write(SessionTokens tokens) async {
    try {
      _storage
        ..setItem(StorageKeys.accessToken, tokens.accessToken)
        ..setItem(StorageKeys.refreshToken, tokens.refreshToken)
        ..setItem(StorageKeys.userId, tokens.userId);
    } on Object catch (error) {
      throw StorageException('Token write failed: ${error.runtimeType}');
    }
  }

  @override
  Future<void> clear() async {
    try {
      _storage
        ..removeItem(StorageKeys.accessToken)
        ..removeItem(StorageKeys.refreshToken)
        ..removeItem(StorageKeys.userId);
    } on Object catch (error) {
      throw StorageException('Token clear failed: ${error.runtimeType}');
    }
  }
}

/// Keeps tokens in memory only (development mocks and tests).
final class MemoryTokenStorage implements TokenStorage {
  MemoryTokenStorage();

  SessionTokens? _tokens;

  @override
  Future<SessionTokens?> read() async => _tokens;

  @override
  Future<void> write(SessionTokens tokens) async => _tokens = tokens;

  @override
  Future<void> clear() async => _tokens = null;
}
