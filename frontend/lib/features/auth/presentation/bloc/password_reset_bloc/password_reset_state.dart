part of 'password_reset_bloc.dart';

final class PasswordResetState extends Equatable {
  const PasswordResetState({
    this.status = LoadStatus.initial,
    this.message,
    this.failure,
  });

  final LoadStatus status;

  /// Generic server confirmation of a request.
  final String? message;
  final Failure? failure;

  PasswordResetState copyWith({
    LoadStatus? status,
    String? message,
    Failure? failure,
    bool resetFailure = false,
  }) {
    return PasswordResetState(
      status: status ?? this.status,
      message: message ?? this.message,
      failure: resetFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, message, failure];
}
