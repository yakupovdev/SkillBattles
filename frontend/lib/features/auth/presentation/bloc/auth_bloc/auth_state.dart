part of 'auth_bloc.dart';

final class AuthState extends Equatable {
  const AuthState({
    this.ageResult,
    this.submitStatus = LoadStatus.initial,
    this.failure,
  });

  /// `null` until the birth input is checked.
  final AgeCheckResult? ageResult;
  final LoadStatus submitStatus;
  final Failure? failure;

  bool get canEnterCredentials => ageResult == AgeCheckResult.eligible;

  /// Server message of a field, e.g. `nickname`.
  String? fieldError(String field) => switch (failure) {
    ApiFailure(:final Map<String, String> fieldErrors) ||
    ValidationFailure(
      :final Map<String, String> fieldErrors,
    ) => fieldErrors[field],
    _ => null,
  };

  AuthState copyWith({
    AgeCheckResult? ageResult,
    LoadStatus? submitStatus,
    Failure? failure,
    bool resetAgeResult = false,
    bool resetFailure = false,
  }) {
    return AuthState(
      ageResult: resetAgeResult ? null : ageResult ?? this.ageResult,
      submitStatus: submitStatus ?? this.submitStatus,
      failure: resetFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => <Object?>[ageResult, submitStatus, failure];
}
