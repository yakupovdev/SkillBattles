import 'package:skill_battles/core/utils/network/api_client.dart';
import 'package:skill_battles/dev/mock_backend.dart';

/// DEVELOPMENT ONLY. Routes every request of the real remote sources to the
/// in-memory [MockBackend], so the app runs end to end without a server.
final class MockApiClient implements ApiClient {
  const MockApiClient({required this._backend});

  final MockBackend _backend;

  @override
  Future<Object?> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) => _backend.handle('GET', path, query: queryParameters);

  @override
  Future<Object?> post(
    String path, {
    Object? data,
    Map<String, dynamic>? headers,
  }) => _backend.handle('POST', path, body: data);

  @override
  Future<Object?> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? headers,
  }) => _backend.handle('PATCH', path, body: data);

  @override
  Future<Object?> delete(String path, {Map<String, dynamic>? headers}) =>
      _backend.handle('DELETE', path);
}
