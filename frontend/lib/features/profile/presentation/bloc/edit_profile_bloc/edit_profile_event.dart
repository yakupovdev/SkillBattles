part of 'edit_profile_bloc.dart';

sealed class EditProfileEvent extends Equatable {
  const EditProfileEvent();

  @override
  List<Object?> get props => <Object?>[];
}

final class EditProfileNicknameSubmitted extends EditProfileEvent {
  const EditProfileNicknameSubmitted(this.params);

  final UpdateProfileParamsEntity params;

  @override
  List<Object?> get props => <Object?>[params];
}

final class EditProfilePasswordSubmitted extends EditProfileEvent {
  const EditProfilePasswordSubmitted(this.params);

  final UpdateProfileParamsEntity params;

  @override
  List<Object?> get props => <Object?>[params];
}
