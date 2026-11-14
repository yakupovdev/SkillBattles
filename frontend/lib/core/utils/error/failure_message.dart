import 'package:skill_battles/core/utils/error/failure.dart';

/// User-facing English text of a [Failure]. Features add their own
/// extensions for specific codes and fall back to [userMessage].
extension FailureMessage on Failure {
  String get userMessage => switch (this) {
    ConnectionFailure() =>
      "Can't reach SkillBattles. Check your connection and try again.",
    TimeoutFailure() => 'The server is taking too long. Please try again.',
    final ApiFailure api =>
      api.message.isEmpty
          ? 'Something went wrong. Please try again.'
          : api.message,
    final ValidationFailure validation => validation.message,
    ParsingFailure() =>
      'The app received an unexpected answer. Please update or try again.',
    StorageFailure() => "Couldn't access secure storage on this device.",
    UnexpectedFailure() => 'Something went wrong. Please try again.',
  };
}
