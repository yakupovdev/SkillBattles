import 'package:dio/dio.dart';

import 'package:skill_battles/core/utils/error/failure_mapper.dart';

/// Last interceptor: stores the mapped `Failure` as [DioException.error], so
/// repositories get the typed failure from `mapExceptionToFailure`.
final class ErrorInterceptor extends Interceptor {
  const ErrorInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(
      err.copyWith(error: mapExceptionToFailure(err, err.stackTrace)),
    );
  }
}
