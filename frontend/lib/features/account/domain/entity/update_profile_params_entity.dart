import 'package:equatable/equatable.dart';

/// Partial profile update: a nickname and/or the password pair. Email
/// never changes.
final class UpdateProfileParamsEntity extends Equatable {
  const UpdateProfileParamsEntity({
    this.nickname,
    this.currentPassword,
    this.newPassword,
  });

  final String? nickname;
  final String? currentPassword;
  final String? newPassword;

  bool get isEmpty =>
      nickname == null && currentPassword == null && newPassword == null;

  @override
  String toString() => 'UpdateProfileParamsEntity(nickname: $nickname)';

  @override
  List<Object?> get props => <Object?>[nickname, currentPassword, newPassword];
}
