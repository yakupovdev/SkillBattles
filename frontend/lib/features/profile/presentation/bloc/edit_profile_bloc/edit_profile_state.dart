part of 'edit_profile_bloc.dart';

final class EditProfileState extends Equatable {
  const EditProfileState({
    this.nicknameStatus = LoadStatus.initial,
    this.nicknameFailure,
    this.passwordStatus = LoadStatus.initial,
    this.passwordFailure,
    this.result,
  });

  final LoadStatus nicknameStatus;
  final Failure? nicknameFailure;
  final LoadStatus passwordStatus;
  final Failure? passwordFailure;
  final UpdateProfileResultEntity? result;

  EditProfileState copyWith({
    LoadStatus? nicknameStatus,
    Failure? nicknameFailure,
    LoadStatus? passwordStatus,
    Failure? passwordFailure,
    UpdateProfileResultEntity? result,
    bool resetNicknameFailure = false,
    bool resetPasswordFailure = false,
  }) {
    return EditProfileState(
      nicknameStatus: nicknameStatus ?? this.nicknameStatus,
      nicknameFailure: resetNicknameFailure
          ? null
          : nicknameFailure ?? this.nicknameFailure,
      passwordStatus: passwordStatus ?? this.passwordStatus,
      passwordFailure: resetPasswordFailure
          ? null
          : passwordFailure ?? this.passwordFailure,
      result: result ?? this.result,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    nicknameStatus,
    nicknameFailure,
    passwordStatus,
    passwordFailure,
    result,
  ];
}
