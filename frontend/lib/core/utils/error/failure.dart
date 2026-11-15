import 'package:equatable/equatable.dart';

/// Expected failure of an operation, returned through `Either.left`.
sealed class Failure extends Equatable {
  const Failure();

  /// Stable API error code, `null` when the server was not reached.
  String? get code => null;

  /// Whether this failure carries the API error [value].
  bool hasCode(String value) => code == value;

  @override
  List<Object?> get props => <Object?>[];
}

/// The server could not be reached.
final class ConnectionFailure extends Failure {
  const ConnectionFailure();
}

/// The request or the response took too long.
final class TimeoutFailure extends Failure {
  const TimeoutFailure();
}

/// The server answered with an `ErrorResponse`.
final class ApiFailure extends Failure {
  const ApiFailure({
    required this.statusCode,
    required this.errorCode,
    required this.message,
    this.fieldErrors = const <String, String>{},
    this.resetsAt,
    this.retryAfter,
  });

  final int statusCode;
  final String errorCode;

  /// English, safe server message (never contains secrets).
  final String message;

  /// Request property path → message.
  final Map<String, String> fieldErrors;

  /// Next ET midnight for `DAILY_LIMIT_REACHED`; the exact server instant
  /// the next sticker is allowed for `STICKER_COOLDOWN`; `null` otherwise.
  final DateTime? resetsAt;

  /// `Retry-After` of a 429, when present.
  final Duration? retryAfter;

  @override
  String get code => errorCode;

  @override
  List<Object?> get props => <Object?>[
    statusCode,
    errorCode,
    message,
    fieldErrors,
    resetsAt,
    retryAfter,
  ];
}

/// Input rejected by a use case before any request was sent.
final class ValidationFailure extends Failure {
  const ValidationFailure({
    required this.message,
    this.fieldErrors = const <String, String>{},
  });

  final String message;
  final Map<String, String> fieldErrors;

  @override
  List<Object?> get props => <Object?>[message, fieldErrors];
}

/// A response had a shape the client cannot read.
final class ParsingFailure extends Failure {
  const ParsingFailure(this.details);

  /// Class, key and error text only — never the raw body.
  final String details;

  @override
  List<Object?> get props => <Object?>[details];
}

/// The secure storage failed.
final class StorageFailure extends Failure {
  const StorageFailure(this.details);

  final String details;

  @override
  List<Object?> get props => <Object?>[details];
}

/// Anything else; details go to the log, never to the user.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(this.details);

  final String details;

  @override
  List<Object?> get props => <Object?>[details];
}
