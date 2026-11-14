import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/auth/domain/entity/password_reset_request_params_entity.dart';

part 'password_reset_request_model.g.dart';

/// Body of POST /auth/password-reset/request.
@JsonSerializable(createFactory: false)
final class PasswordResetRequestModel {
  const PasswordResetRequestModel({required this.email});

  Map<String, dynamic> toJson() => _$PasswordResetRequestModelToJson(this);

  final String email;

  factory PasswordResetRequestModel.fromEntity(
    PasswordResetRequestParamsEntity params,
  ) => PasswordResetRequestModel(email: params.email.trim().toLowerCase());
}
