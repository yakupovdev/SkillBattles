import 'package:dio/dio.dart';

import 'package:skill_battles/core/utils/network/app_api.dart';
import 'package:skill_battles/core/utils/session/auth_session.dart';

/// Adds `Authorization: Bearer <access>` and, on a 401, refreshes the pair
/// once (single flight in [AuthSession]) and repeats the request once.
///
/// Requests that already carry an `Authorization` header (refresh, logout)
/// are left alone.
final class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this._session, required this._dio});

  final AuthSession _session;
  final Dio _dio;

  static const String _retriedKey = 'auth.retried';
  static const String _usedTokenKey = 'auth.usedToken';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final bool hasOwnHeader = options.headers.containsKey(
      AppApi.authorizationHeader,
    );
    final String? token = _session.accessToken;
    if (!hasOwnHeader && token != null) {
      options.headers[AppApi.authorizationHeader] =
          '${AppApi.bearerPrefix} $token';
      options.extra[_usedTokenKey] = token;
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final RequestOptions options = err.requestOptions;
    final Object? usedToken = options.extra[_usedTokenKey];
    final bool canRetry =
        err.response?.statusCode == 401 &&
        usedToken is String &&
        options.extra[_retriedKey] != true;
    if (!canRetry) {
      handler.next(err);
      return;
    }
    // Another request may have rotated the pair already.
    final bool fresh =
        _session.accessToken != null && _session.accessToken != usedToken
        ? true
        : await _session.refresh();
    final String? token = _session.accessToken;
    if (!fresh || token == null) {
      handler.next(err);
      return;
    }
    options.extra[_retriedKey] = true;
    options.extra[_usedTokenKey] = token;
    options.headers[AppApi.authorizationHeader] =
        '${AppApi.bearerPrefix} $token';
    try {
      handler.resolve(await _dio.fetch<Object?>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}
