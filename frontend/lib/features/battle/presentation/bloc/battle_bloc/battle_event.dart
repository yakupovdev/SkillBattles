part of 'battle_bloc.dart';

sealed class BattleEvent extends Equatable {
  const BattleEvent();

  @override
  List<Object?> get props => <Object?>[];
}

final class BattleStarted extends BattleEvent {
  const BattleStarted();
}

/// Reads the snapshot again. [entitlementsChanged] applies it even at the
/// same battle version, so a downgrade hides paid fields at once.
final class BattleRefreshRequested extends BattleEvent {
  const BattleRefreshRequested({this.entitlementsChanged = false});

  final bool entitlementsChanged;

  @override
  List<Object?> get props => <Object?>[entitlementsChanged];
}

/// Local choice before Submit.
final class BattleOptionSelected extends BattleEvent {
  const BattleOptionSelected(this.optionId);

  final String optionId;

  @override
  List<Object?> get props => <Object?>[optionId];
}

/// Submits (or retries) the selected option.
final class BattleAnswerSubmitted extends BattleEvent {
  const BattleAnswerSubmitted();
}

final class BattleReadyPressed extends BattleEvent {
  const BattleReadyPressed();
}

final class BattleSurrenderRequested extends BattleEvent {
  const BattleSurrenderRequested();
}

final class _SnapshotReceived extends BattleEvent {
  const _SnapshotReceived(this.snapshot);

  final BattleSnapshotEntity snapshot;

  @override
  List<Object?> get props => <Object?>[snapshot];
}

final class _ConnectionChanged extends BattleEvent {
  const _ConnectionChanged(this.status);

  final RealtimeStatus status;

  @override
  List<Object?> get props => <Object?>[status];
}
