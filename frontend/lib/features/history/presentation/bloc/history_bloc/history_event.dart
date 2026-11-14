part of 'history_bloc.dart';

sealed class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// First load, and a re-read after an entitlement change.
final class HistoryStarted extends HistoryEvent {
  const HistoryStarted();
}

/// A new page or filter. `null` filters mean "all".
final class HistoryParamsChanged extends HistoryEvent {
  const HistoryParamsChanged({this.page = 0, this.mode, this.disciplineCode});

  final int page;
  final BattleMode? mode;
  final String? disciplineCode;

  @override
  List<Object?> get props => <Object?>[page, mode, disciplineCode];
}
