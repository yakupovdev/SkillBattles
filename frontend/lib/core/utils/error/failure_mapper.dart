import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/error_response_model.dart';
import 'package:skill_battles/core/data/models/field_error_model.dart';
import 'package:skill_battles/core/utils/error/app_exception.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/network/app_api.dart';

/// The only exception → [Failure] conversion. Repositories call it from
/// their `catch` blocks; `ErrorInterceptor` calls it for every
/// [DioException] and stores the result as `DioException.error`.
Failure mapExceptionToFailure(Object exception, [StackTrace? stackTrace]) {
  return switch (exception) {
    final DioException dio => _mapDio(dio, stackTrace),
    final CheckedFromJsonException json => _parsing(
      '${json.className}.${json.key}: ${json.message}',
      stackTrace,
    ),
    final ParsingException parsing => _parsing(parsing.message, stackTrace),
    final StorageException storage => StorageFailure(storage.message),
    _ => _unexpected(exception.runtimeType.toString(), stackTrace),
  };
}

Failure _mapDio(DioException exception, StackTrace? stackTrace) {
  final Object? stored = exception.error;
  if (stored is Failure) return stored;
  switch (exception.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const TimeoutFailure();
    case DioExceptionType.connectionError:
      return const ConnectionFailure();
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return exception.response == null
          ? const ConnectionFailure()
          : _mapResponse(exception.response!, stackTrace);
    case DioExceptionType.badResponse:
      final Response<Object?>? response = exception.response;
      if (response == null) return const ConnectionFailure();
      return _mapResponse(response, stackTrace);
  }
}

Failure _mapResponse(Response<Object?> response, StackTrace? stackTrace) {
  final int status = response.statusCode ?? 0;
  final Object? body = response.data;
  final Duration? retryAfter = _retryAfter(
    response.headers.value(AppApi.retryAfterHeader),
  );
  if (body is Map<String, dynamic>) {
    try {
      final ErrorResponseModel error = ErrorResponseModel.fromJson(body);
      return ApiFailure(
        statusCode: status,
        errorCode: error.code,
        message: error.message,
        fieldErrors: <String, String>{
          for (final FieldErrorModel field in error.fieldErrors)
            field.field: field.message,
        },
        resetsAt: error.resetsAt,
        retryAfter: retryAfter,
      );
    } on CheckedFromJsonException catch (error) {
      developer.log(
        'Malformed ErrorResponse (${error.key})',
        name: 'failure_mapper',
        stackTrace: stackTrace,
      );
    }
  }
  return ApiFailure(
    statusCode: status,
    errorCode: status >= 500 ? 'INTERNAL_ERROR' : 'HTTP_$status',
    message: 'Something went wrong. Please try again.',
    retryAfter: retryAfter,
  );
}

Duration? _retryAfter(String? header) {
  final int? seconds = int.tryParse(header?.trim() ?? '');
  return seconds == null ? null : Duration(seconds: seconds);
}

Failure _parsing(String details, StackTrace? stackTrace) {
  developer.log(details, name: 'failure_mapper', stackTrace: stackTrace);
  return ParsingFailure(details);
}

Failure _unexpected(String details, StackTrace? stackTrace) {
  developer.log(details, name: 'failure_mapper', stackTrace: stackTrace);
  return UnexpectedFailure(details);
}
