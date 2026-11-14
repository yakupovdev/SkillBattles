import 'package:equatable/equatable.dart';

/// The one-use token from the reset link and the new password.
final class PasswordResetConfirmParamsEntity extends Equatable {
  const PasswordResetConfirmParamsEntity({
    required this.token,
    required this.newPassword,
  });

  final String token;
  final String newPassword;

  // The token is a secret.
  @override
  String toString() => 'PasswordResetConfirmParamsEntity()';

  @override
  List<Object?> get props => <Object?>[token, newPassword];
}
