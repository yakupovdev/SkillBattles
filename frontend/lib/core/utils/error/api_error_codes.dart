/// Stable `ErrorResponse.code` values of the SkillBattles API that the client
/// reacts to. Shared by several features, so they live in core.
abstract final class ApiErrorCodes {
  static const String validationError = 'VALIDATION_ERROR';
  static const String unauthorized = 'UNAUTHORIZED';
  static const String forbidden = 'FORBIDDEN';
  static const String rateLimited = 'RATE_LIMITED';
  static const String internalError = 'INTERNAL_ERROR';

  // Auth and profile.
  static const String ageRestricted = 'AGE_RESTRICTED';
  static const String invalidCredentials = 'INVALID_CREDENTIALS';
  static const String emailAlreadyExists = 'EMAIL_ALREADY_EXISTS';
  static const String nicknameAlreadyExists = 'NICKNAME_ALREADY_EXISTS';
  static const String invalidResetToken = 'INVALID_RESET_TOKEN';
  static const String emailServiceUnavailable = 'EMAIL_SERVICE_UNAVAILABLE';
  static const String emptyUpdate = 'EMPTY_UPDATE';
  static const String invalidCurrentPassword = 'INVALID_CURRENT_PASSWORD';

  // Limits and access.
  static const String dailyLimitReached = 'DAILY_LIMIT_REACHED';
  static const String quotaExhausted = 'QUOTA_EXHAUSTED';
  static const String historyAccessRequired = 'HISTORY_ACCESS_REQUIRED';
  static const String proRequired = 'PRO_REQUIRED';

  // Matchmaking, rooms and battles.
  static const String activityConflict = 'ACTIVITY_CONFLICT';
  static const String contentUnavailable = 'CONTENT_UNAVAILABLE';
  static const String disciplineUnavailable = 'DISCIPLINE_UNAVAILABLE';
  static const String matchAlreadyFound = 'MATCH_ALREADY_FOUND';
  static const String duelNotFound = 'DUEL_NOT_FOUND';
  static const String duelExpired = 'DUEL_EXPIRED';
  static const String duelNotJoinable = 'DUEL_NOT_JOINABLE';
  static const String selfJoinNotAllowed = 'SELF_JOIN_NOT_ALLOWED';
  static const String battleNotFound = 'BATTLE_NOT_FOUND';
  static const String battleNotFinished = 'BATTLE_NOT_FINISHED';
  static const String invalidBattleState = 'INVALID_BATTLE_STATE';
  static const String realtimeConnectionRequired =
      'REALTIME_CONNECTION_REQUIRED';
  static const String idempotencyConflict = 'IDEMPOTENCY_CONFLICT';
  static const String answerAlreadySubmitted = 'ANSWER_ALREADY_SUBMITTED';
  static const String roundClosed = 'ROUND_CLOSED';
  static const String invalidOption = 'INVALID_OPTION';

  // Battle stickers.
  static const String stickerCooldown = 'STICKER_COOLDOWN';
  static const String invalidStickerId = 'INVALID_STICKER_ID';
  static const String stickersNotAllowed = 'STICKERS_NOT_ALLOWED';

  // Rematch and reports.
  static const String rematchNotAllowed = 'REMATCH_NOT_ALLOWED';
  static const String rematchExpired = 'REMATCH_EXPIRED';
  static const String rematchNotFound = 'REMATCH_NOT_FOUND';
  static const String roundNotFound = 'ROUND_NOT_FOUND';
  static const String roundNotRevealed = 'ROUND_NOT_REVEALED';
  static const String reportAlreadyExists = 'REPORT_ALREADY_EXISTS';

  // Friends and room invitations.
  static const String friendNotFound = 'FRIEND_NOT_FOUND';
  static const String friendCodeNotFound = 'FRIEND_CODE_NOT_FOUND';
  static const String selfFriendRequestNotAllowed =
      'SELF_FRIEND_REQUEST_NOT_ALLOWED';
  static const String friendAlreadyExists = 'FRIEND_ALREADY_EXISTS';
  static const String friendRequestAlreadyReceived =
      'FRIEND_REQUEST_ALREADY_RECEIVED';
  static const String friendRequestNotFound = 'FRIEND_REQUEST_NOT_FOUND';
  static const String friendRequestNotPending = 'FRIEND_REQUEST_NOT_PENDING';
  static const String duelInvitationAlreadyPending =
      'DUEL_INVITATION_ALREADY_PENDING';
  static const String duelInvitationNotFound = 'DUEL_INVITATION_NOT_FOUND';
  static const String duelInvitationNotPending = 'DUEL_INVITATION_NOT_PENDING';
  static const String duelInvitationExpired = 'DUEL_INVITATION_EXPIRED';

  // Billing.
  static const String subscriptionAlreadyActive = 'SUBSCRIPTION_ALREADY_ACTIVE';
  static const String checkoutInProgress = 'CHECKOUT_IN_PROGRESS';
  static const String billingUnavailable = 'BILLING_UNAVAILABLE';
  static const String billingCustomerNotFound = 'BILLING_CUSTOMER_NOT_FOUND';

  // Field names reported in `fieldErrors`.
  static const String birthDayField = 'birthDay';
}
