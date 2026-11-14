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
