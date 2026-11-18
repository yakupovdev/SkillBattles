import 'package:test/test.dart';

import 'package:skill_battles/core/presentation/extensions/play_failure_message.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/feature_flags.dart';

ApiFailure _failure(String code) => ApiFailure(statusCode: 403, errorCode: code, message: 'Server message');

void main() {
  group('PlayFailureMessage.playMessage without billing', () {
    final Matcher mentionsPayments = anyOf(
      contains('Pro'),
      contains('free'),
      contains('Free'),
    );

    test('the daily limit message does not offer Pro or say free', () {
      final String message = _failure(
        ApiErrorCodes.dailyLimitReached,
      ).playMessage(DateTime.utc(2026, 11, 18, 12));

      expect(message, contains("You've used today's ranked matches."));
      expect(message, isNot(mentionsPayments));
    });

    test('the history access message does not offer Pro', () {
      final String message = _failure(
        ApiErrorCodes.historyAccessRequired,
      ).playMessage(DateTime.utc(2026, 11, 18, 12));

      expect(message, 'This match is older than your latest 10.');
    });
  }, skip: FeatureFlags.billing ? 'Billing is on in this build' : false);
}
