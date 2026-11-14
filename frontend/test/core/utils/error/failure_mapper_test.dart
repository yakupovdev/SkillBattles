import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skill_battles/core/utils/error/app_exception.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/error/failure_mapper.dart';

DioException _response(int status, Object? body, {String? retryAfter}) {
  final RequestOptions options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: status,
      data: body,
      headers: Headers.fromMap(<String, List<String>>{
        if (retryAfter != null) 'retry-after': <String>[retryAfter],
      }),
    ),
  );
}

void main() {
  test('a 429 DAILY_LIMIT_REACHED keeps resetsAt and Retry-After', () {
    final Failure failure = mapExceptionToFailure(
      _response(429, <String, dynamic>{
        'code': 'DAILY_LIMIT_REACHED',
        'message': 'You have used all 5 free ranked matches for today.',
        'fieldErrors': <Object?>[],
        'resetsAt': '2026-11-15T05:00:00Z',
      }, retryAfter: '3600'),
    );

    expect(failure, isA<ApiFailure>());
    final ApiFailure api = failure as ApiFailure;
    expect(api.code, 'DAILY_LIMIT_REACHED');
    expect(api.resetsAt, DateTime.utc(2026, 11, 15, 5));
    expect(api.retryAfter, const Duration(hours: 1));
  });

  test('field errors are mapped by field path', () {
    final Failure failure = mapExceptionToFailure(
      _response(400, <String, dynamic>{
        'code': 'VALIDATION_ERROR',
        'message': 'Invalid request.',
        'fieldErrors': <Map<String, String>>[
          <String, String>{'field': 'birthDay', 'message': 'Required.'},
        ],
        'resetsAt': null,
      }),
    );

    expect((failure as ApiFailure).fieldErrors, <String, String>{
      'birthDay': 'Required.',
    });
  });

  test('a body that is not an ErrorResponse still becomes an ApiFailure', () {
    final Failure failure = mapExceptionToFailure(
      _response(502, 'Bad gateway'),
    );

    expect(failure, isA<ApiFailure>());
    expect(failure.code, 'INTERNAL_ERROR');
  });

  test('transport errors map to connection and timeout failures', () {
    final RequestOptions options = RequestOptions(path: '/x');
    expect(
      mapExceptionToFailure(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      ),
      isA<ConnectionFailure>(),
    );
    expect(
      mapExceptionToFailure(
        DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        ),
      ),
      isA<TimeoutFailure>(),
    );
  });

  test('a stored failure is returned unchanged', () {
    const Failure stored = ConnectionFailure();
    expect(
      mapExceptionToFailure(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          error: stored,
        ),
      ),
      same(stored),
    );
  });

  test('a parsing exception becomes a ParsingFailure', () {
    expect(
      mapExceptionToFailure(const ParsingException('Expected a JSON object.')),
      isA<ParsingFailure>(),
    );
  });
}
