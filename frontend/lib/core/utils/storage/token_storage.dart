import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

final class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<SessionTokens?> read() async {
    try {
      final String? access = await _storage.read(key: StorageKeys.accessToken);
      final String? refresh = await _storage.read(
        key: StorageKeys.refreshToken,
      );
      final String? userId = await _storage.read(key: StorageKeys.userId);
      if (access == null || refresh == null || userId == null) return null;
      return SessionTokens(
        accessToken: access,
        refreshToken: refresh,
        userId: userId,
      );
    } on Exception catch (error) {
      throw StorageException('Token read failed: ${error.runtimeType}');
    }
  }

  @override
  Future<void> write(SessionTokens tokens) async {
    try {
      await _storage.write(
        key: StorageKeys.accessToken,
        value: tokens.accessToken,
      );
      await _storage.write(
        key: StorageKeys.refreshToken,
        value: tokens.refreshToken,
      );
      await _storage.write(key: StorageKeys.userId, value: tokens.userId);
    } on Exception catch (error) {
      throw StorageException('Token write failed: ${error.runtimeType}');
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: StorageKeys.accessToken);
      await _storage.delete(key: StorageKeys.refreshToken);
      await _storage.delete(key: StorageKeys.userId);
    } on Exception catch (error) {
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
