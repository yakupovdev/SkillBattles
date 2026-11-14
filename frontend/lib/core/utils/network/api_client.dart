import 'package:dio/dio.dart';

/// Shared HTTP client abstraction used by remote sources.
///
/// Methods return the decoded response body and let transport errors
/// propagate as [DioException].
abstract interface class ApiClient {
  Future<Object?> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  });

  Future<Object?> post(
    String path, {
    Object? data,
    Map<String, dynamic>? headers,
  });

  Future<Object?> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? headers,
  });

  Future<Object?> delete(String path, {Map<String, dynamic>? headers});
}

final class DioApiClient implements ApiClient {
  const DioApiClient(this._dio);

  final Dio _dio;

  @override
  Future<Object?> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    final Response<Object?> response = await _dio.get<Object?>(
      path,
      queryParameters: queryParameters,
      options: Options(headers: headers),
    );
    return response.data;
  }

  @override
  Future<Object?> post(
    String path, {
    Object? data,
    Map<String, dynamic>? headers,
  }) async {
    final Response<Object?> response = await _dio.post<Object?>(
      path,
      data: data,
      options: Options(headers: headers),
    );
    return response.data;
  }

  @override
  Future<Object?> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? headers,
  }) async {
    final Response<Object?> response = await _dio.patch<Object?>(
      path,
      data: data,
      options: Options(headers: headers),
    );
    return response.data;
  }

  @override
  Future<Object?> delete(String path, {Map<String, dynamic>? headers}) async {
    final Response<Object?> response = await _dio.delete<Object?>(
      path,
      options: Options(headers: headers),
    );
    return response.data;
  }
}
