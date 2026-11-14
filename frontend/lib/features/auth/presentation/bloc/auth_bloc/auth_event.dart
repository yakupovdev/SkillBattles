part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The neutral birth input before any credentials.
final class AuthAgeSubmitted extends AuthEvent {
  const AuthAgeSubmitted(this.params);

  final AgeCheckParamsEntity params;

  @override
  List<Object?> get props => <Object?>[params];
}

/// The birth input changed after a check.
final class AuthAgeEdited extends AuthEvent {
  const AuthAgeEdited();
}

final class AuthRegisterSubmitted extends AuthEvent {
  const AuthRegisterSubmitted(this.params);

  final RegisterParamsEntity params;

  @override
  List<Object?> get props => <Object?>[params];
}

final class AuthLoginSubmitted extends AuthEvent {
  const AuthLoginSubmitted(this.params);

  final LoginParamsEntity params;

  @override
  List<Object?> get props => <Object?>[params];
}

/// Clears a stale server error once the user edits a field.
final class AuthFieldEdited extends AuthEvent {
  const AuthFieldEdited();
}
