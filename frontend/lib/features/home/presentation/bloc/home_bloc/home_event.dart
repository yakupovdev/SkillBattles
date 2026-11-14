part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => <Object?>[];
}

final class HomeStarted extends HomeEvent {
  const HomeStarted();
}

/// Re-read after returning to the screen or an entitlement change.
final class HomeRefreshRequested extends HomeEvent {
  const HomeRefreshRequested();
}

final class HomeDisciplineSelected extends HomeEvent {
  const HomeDisciplineSelected(this.code);

  final String code;

  @override
  List<Object?> get props => <Object?>[code];
}

final class HomeJoinDuelSubmitted extends HomeEvent {
  const HomeJoinDuelSubmitted(this.params);

  final JoinDuelParamsEntity params;

  @override
  List<Object?> get props => <Object?>[params];
}

final class HomeJoinCodeEdited extends HomeEvent {
  const HomeJoinCodeEdited();
}
