import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/user_entity.dart';

final class UpdateProfileResultEntity extends Equatable {
  const UpdateProfileResultEntity({
    required this.user,
    required this.passwordChanged,
    required this.reauthenticationRequired,
  });

  final UserEntity user;
  final bool passwordChanged;

  /// After a password change every refresh token is revoked: the session on
  /// this device has been cleared and the user logs in again.
  final bool reauthenticationRequired;

  @override
  List<Object?> get props => <Object?>[
    user,
    passwordChanged,
    reauthenticationRequired,
  ];
}
