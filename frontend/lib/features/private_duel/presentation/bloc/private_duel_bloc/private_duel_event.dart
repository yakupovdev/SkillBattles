part of 'private_duel_bloc.dart';

sealed class PrivateDuelEvent extends Equatable {
  const PrivateDuelEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Creates a room in [disciplineCode], or resumes [duelId].
final class PrivateDuelStarted extends PrivateDuelEvent {
  const PrivateDuelStarted({this.disciplineCode, this.duelId});

  final String? disciplineCode;
  final String? duelId;

  @override
  List<Object?> get props => <Object?>[disciplineCode, duelId];
}

final class PrivateDuelCancelRequested extends PrivateDuelEvent {
  const PrivateDuelCancelRequested();
}

final class _DuelReceived extends PrivateDuelEvent {
  const _DuelReceived(this.duel);

  final DuelEntity duel;

  @override
  List<Object?> get props => <Object?>[duel];
}

final class _DuelRefreshTick extends PrivateDuelEvent {
  const _DuelRefreshTick();
}
