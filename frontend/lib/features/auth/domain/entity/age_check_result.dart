/// Client pre-check of the age screen. The server re-checks on sign-up and
/// has the final word (`AGE_RESTRICTED`, `birthDay` field error).
enum AgeCheckResult {
  /// 13 or older: continue to the credentials.
  eligible,

  /// Turns 13 in the current ET month: the day is needed to decide.
  needsDay,

  /// Younger than 13.
  restricted,

  /// A future or non-existent date.
  invalidDate,
}
