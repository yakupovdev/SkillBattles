import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/auth/domain/entity/login_params_entity.dart';

part 'login_request_model.g.dart';

/// Body of POST /auth/login.
@JsonSerializable(createFactory: false)
final class LoginRequestModel {
  const LoginRequestModel({required this.email, required this.password});

  Map<String, dynamic> toJson() => _$LoginRequestModelToJson(this);

  final String email;
  final String password;

  factory LoginRequestModel.fromEntity(LoginParamsEntity params) =>
      LoginRequestModel(
        email: params.email.trim().toLowerCase(),
        password: params.password,
      );
}
