import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/auth/domain/entity/register_params_entity.dart';

part 'register_request_model.g.dart';

/// Body of POST /auth/register.
@JsonSerializable(createFactory: false)
final class RegisterRequestModel {
  const RegisterRequestModel({
    required this.email,
    required this.password,
    required this.nickname,
    required this.birthYear,
    required this.birthMonth,
    required this.birthDay,
  });

  Map<String, dynamic> toJson() => _$RegisterRequestModelToJson(this);

  final String email;
  final String password;
  final String nickname;
  final int birthYear;
  final int birthMonth;
  final int? birthDay;

  /// Email is trimmed and lower-cased; the password is sent as typed.
  factory RegisterRequestModel.fromEntity(RegisterParamsEntity params) =>
      RegisterRequestModel(
        email: params.email.trim().toLowerCase(),
        password: params.password,
        nickname: params.nickname.trim(),
        birthYear: params.birthYear,
        birthMonth: params.birthMonth,
        birthDay: params.birthDay,
      );
}
