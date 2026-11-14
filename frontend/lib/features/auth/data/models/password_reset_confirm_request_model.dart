import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/auth/domain/entity/password_reset_confirm_params_entity.dart';

part 'password_reset_confirm_request_model.g.dart';

/// Body of POST /auth/password-reset/confirm.
@JsonSerializable(createFactory: false)
final class PasswordResetConfirmRequestModel {
  const PasswordResetConfirmRequestModel({
    required this.token,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() =>
      _$PasswordResetConfirmRequestModelToJson(this);

  final String token;
  final String newPassword;

  factory PasswordResetConfirmRequestModel.fromEntity(
    PasswordResetConfirmParamsEntity params,
  ) => PasswordResetConfirmRequestModel(
    token: params.token,
    newPassword: params.newPassword,
  );
}
