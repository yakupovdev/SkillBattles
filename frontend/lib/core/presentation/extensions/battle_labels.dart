import 'package:skill_battles/core/domain/entity/battle_mode.dart';
import 'package:skill_battles/core/domain/entity/battle_outcome.dart';
import 'package:skill_battles/core/domain/entity/battle_reason.dart';
import 'package:skill_battles/core/domain/entity/difficulty.dart';

/// English display names of the shared battle enums.
extension BattleModeLabel on BattleMode {
  String get label => switch (this) {
    BattleMode.ranked => 'Ranked',
    BattleMode.private => 'Private',
  };
}

extension BattleOutcomeLabel on BattleOutcome {
  String get label => switch (this) {
    BattleOutcome.win => 'WIN',
    BattleOutcome.loss => 'LOSS',
    BattleOutcome.draw => 'DRAW',
    BattleOutcome.cancelled => 'CANCELLED',
  };
}

extension DifficultyLabel on Difficulty {
  String get label => switch (this) {
    Difficulty.easy => 'Easy',
    Difficulty.medium => 'Medium',
    Difficulty.hard => 'Hard',
  };
}

extension BattleReasonLabel on BattleReason {
  /// Why the match ended, from the reader's point of view.
  String describe({required bool iWon, required bool isDraw}) => switch (this) {
    BattleReason.normal => isDraw ? 'Tie after overtime' : 'All rounds played',
    BattleReason.overtimeWin => iWon ? 'Won in overtime' : 'Lost in overtime',
    BattleReason.surrender => iWon ? 'Opponent surrendered' : 'You surrendered',
    BattleReason.disconnect =>
      iWon ? 'Opponent disconnected' : 'You disconnected',
    BattleReason.readyTimeout => 'Ready check timed out',
    BattleReason.bothDisconnected => 'Both players disconnected',
    BattleReason.serverInterruption => 'Interrupted by a server restart',
    BattleReason.quotaExhausted => 'Daily ranked limit reached',
  };
}

/// Readable fallback for a rank code without the ranks table
/// (`SILVER_II` → `Silver II`). Thresholds always come from the server.
String formatRankCode(String code) => code
    .split('_')
    .map(
      (String part) => part.length <= 3 && RegExp(r'^[IVX]+$').hasMatch(part)
          ? part
          : '${part[0]}${part.substring(1).toLowerCase()}',
    )
    .join(' ');

/// `SAT_MATH` → `SAT Math` when the catalogue name is not at hand.
String formatDisciplineCode(String code) => code
    .split('_')
    .map(
      (String part) => part.length <= 3
          ? part
          : '${part[0]}${part.substring(1).toLowerCase()}',
    )
    .join(' ');
