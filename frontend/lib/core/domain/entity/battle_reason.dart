/// Why a battle ended. The outcome follows the reason, not the score: a
/// forfeit winner can have fewer points.
enum BattleReason {
  normal,
  overtimeWin,
  surrender,
  disconnect,
  readyTimeout,
  bothDisconnected,
  serverInterruption,
  quotaExhausted,
}
