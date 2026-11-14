part of 'profile_bloc.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => <Object?>[];
}

final class ProfileStarted extends ProfileEvent {
  const ProfileStarted();
}

/// Re-read after an entitlement change.
final class ProfileRefreshRequested extends ProfileEvent {
  const ProfileRefreshRequested();
}

final class ProfileDisciplineSelected extends ProfileEvent {
  const ProfileDisciplineSelected(this.code);

  final String code;

  @override
  List<Object?> get props => <Object?>[code];
}

/// A new history page or filter.
final class ProfileHistoryChanged extends ProfileEvent {
  const ProfileHistoryChanged({this.page = 0, this.mode, this.disciplineCode});

  final int page;
  final BattleMode? mode;
  final String? disciplineCode;

  @override
  List<Object?> get props => <Object?>[page, mode, disciplineCode];
}
