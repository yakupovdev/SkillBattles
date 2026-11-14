part of 'battle_result_bloc.dart';

sealed class BattleResultEvent extends Equatable {
  const BattleResultEvent();

  @override
  List<Object?> get props => <Object?>[];
}

final class BattleResultStarted extends BattleResultEvent {
  const BattleResultStarted();
}

/// Re-read after an entitlement change (upgrade/downgrade).
final class BattleResultRefreshRequested extends BattleResultEvent {
  const BattleResultRefreshRequested();
}

/// Pro filter: wrong and unanswered rounds only.
final class BattleResultMistakesOnlyChanged extends BattleResultEvent {
  const BattleResultMistakesOnlyChanged(this.mistakesOnly);

  final bool mistakesOnly;

  @override
  List<Object?> get props => <Object?>[mistakesOnly];
}

final class BattleResultRematchRequested extends BattleResultEvent {
  const BattleResultRematchRequested();
}

final class BattleResultRematchCancelled extends BattleResultEvent {
  const BattleResultRematchCancelled();
}

final class BattleResultReportSubmitted extends BattleResultEvent {
  const BattleResultReportSubmitted(this.params);

  final ReportParamsEntity params;

  @override
  List<Object?> get props => <Object?>[params];
}

final class BattleResultReportDismissed extends BattleResultEvent {
  const BattleResultReportDismissed();
}

final class _RematchReceived extends BattleResultEvent {
  const _RematchReceived(this.rematch);

  final RematchEntity rematch;

  @override
  List<Object?> get props => <Object?>[rematch];
}
