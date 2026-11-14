part of 'password_reset_bloc.dart';

sealed class PasswordResetEvent extends Equatable {
  const PasswordResetEvent();

  @override
  List<Object?> get props => <Object?>[];
}

final class PasswordResetRequested extends PasswordResetEvent {
  const PasswordResetRequested(this.params);

  final PasswordResetRequestParamsEntity params;

  @override
  List<Object?> get props => <Object?>[params];
}

final class PasswordResetConfirmed extends PasswordResetEvent {
  const PasswordResetConfirmed(this.params);

  final PasswordResetConfirmParamsEntity params;

  @override
  List<Object?> get props => <Object?>[params];
}
