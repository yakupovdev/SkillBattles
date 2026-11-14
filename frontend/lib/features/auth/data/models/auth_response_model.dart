import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/user_model.dart';
import 'package:skill_battles/core/utils/session/session_tokens.dart';

part 'auth_response_model.g.dart';

/// Token pair and the signed-in user.
@JsonSerializable(checked: true, createToJson: false)
final class AuthResponseModel {
  const AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.accessExpiresIn,
    required this.refreshExpiresIn,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseModelFromJson(json);

  @JsonKey(required: true)
  final String accessToken;

  @JsonKey(required: true)
  final String refreshToken;

  @JsonKey(required: true)
  final String tokenType;

  @JsonKey(required: true)
  final int accessExpiresIn;

  @JsonKey(required: true)
  final int refreshExpiresIn;

  @JsonKey(required: true)
  final UserModel user;

  SessionTokens toSessionTokens() => SessionTokens(
    accessToken: accessToken,
    refreshToken: refreshToken,
    userId: user.id,
  );
}
