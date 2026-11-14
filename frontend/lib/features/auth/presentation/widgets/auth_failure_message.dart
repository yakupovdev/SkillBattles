import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';

/// Auth-specific wording; falls back to the server's safe message.
extension AuthFailureMessage on Failure {
  String get authMessage {
    if (hasCode(ApiErrorCodes.invalidCredentials)) {
      return 'Email or password is incorrect.';
    }
    if (hasCode(ApiErrorCodes.ageRestricted)) {
      return 'SkillBattles is available from age 13.';
    }
    if (hasCode(ApiErrorCodes.emailAlreadyExists)) {
      return 'An account with this email already exists. Log in instead.';
    }
    if (hasCode(ApiErrorCodes.nicknameAlreadyExists)) {
      return 'This nickname is taken. Try another one.';
    }
    if (hasCode(ApiErrorCodes.invalidResetToken)) {
      return 'This reset link is invalid or was already used. Request a new one.';
    }
    if (hasCode(ApiErrorCodes.rateLimited)) {
      return 'Too many attempts. Wait a moment and try again.';
    }
    if (hasCode(ApiErrorCodes.emailServiceUnavailable)) {
      return "We couldn't send the email right now. Try again later.";
    }
    return userMessage;
  }
}
