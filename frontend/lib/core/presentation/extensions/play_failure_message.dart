import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';
import 'package:skill_battles/core/utils/feature_flags.dart';

/// Wording for failures of starting or playing a match.
extension PlayFailureMessage on Failure {
  bool get isDailyLimit => hasCode(ApiErrorCodes.dailyLimitReached) || hasCode(ApiErrorCodes.quotaExhausted);

  /// Next ET midnight of a quota failure.
  DateTime? get limitResetsAt => switch (this) {
    ApiFailure(:final DateTime? resetsAt) => resetsAt,
    _ => null,
  };

  String playMessage(DateTime now) {
    if (isDailyLimit) {
      final DateTime? resetsAt = limitResetsAt;
      const String used = FeatureFlags.billing
          ? "You've used today's free ranked matches."
          : "You've used today's ranked matches.";
      return resetsAt == null
          ? used
          : '$used They reset at '
                '${DisplayFormatters.resetsAt(resetsAt, now)}.';
    }
    if (hasCode(ApiErrorCodes.activityConflict)) {
      return 'You already have a match, search or room open. Resume or leave '
          'it first.';
    }
    if (hasCode(ApiErrorCodes.contentUnavailable)) {
      return "There aren't enough questions for this match right now. Try "
          'again later or pick another discipline.';
    }
    if (hasCode(ApiErrorCodes.disciplineUnavailable)) {
      return 'This discipline is not available right now.';
    }
    if (hasCode(ApiErrorCodes.realtimeConnectionRequired)) {
      return 'Connecting to live updates… try again in a moment.';
    }
    if (hasCode(ApiErrorCodes.historyAccessRequired)) {
      return FeatureFlags.billing
          ? 'This match is older than your latest 10. Pro opens your full '
                'history.'
          : 'This match is older than your latest 10.';
    }
    return userMessage;
  }
}
