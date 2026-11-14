/// Server phase of a battle. Overtime reuses [question]/[reveal] with round
/// number 6. Only the server moves phases; local timers never do.
enum BattlePhase {
  waitingReady,
  countdown,
  question,
  reveal,
  finished,
  cancelled;

  bool get isTerminal => this == finished || this == cancelled;
}
