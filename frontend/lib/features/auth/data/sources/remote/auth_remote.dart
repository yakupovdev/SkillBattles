import 'package:skill_battles/core/utils/network/api_client.dart';
import 'package:skill_battles/core/utils/network/app_api.dart';
import 'package:skill_battles/core/utils/network/json_object.dart';
import 'package:skill_battles/features/auth/data/models/accepted_response_model.dart';
import 'package:skill_battles/features/auth/data/models/auth_response_model.dart';
import 'package:skill_battles/features/auth/data/models/login_request_model.dart';
import 'package:skill_battles/features/auth/data/models/password_reset_confirm_request_model.dart';
import 'package:skill_battles/features/auth/data/models/password_reset_request_model.dart';
import 'package:skill_battles/features/auth/data/models/register_request_model.dart';

abstract interface class AuthRemote {
  Future<AuthResponseModel> register(RegisterRequestModel request);

  Future<AuthResponseModel> login(LoginRequestModel request);

  /// Rotates the token pair; [refreshToken] goes in `Authorization`.
  Future<AuthResponseModel> refresh(String refreshToken);

  /// Revokes the refresh token; [refreshToken] goes in `Authorization`.
  Future<void> logout(String refreshToken);

  Future<AcceptedResponseModel> requestPasswordReset(
    PasswordResetRequestModel request,
  );

  Future<void> confirmPasswordReset(PasswordResetConfirmRequestModel request);
}

final class AuthRemoteImpl implements AuthRemote {
  const AuthRemoteImpl(this._client);

  final ApiClient _client;

  static Map<String, dynamic> _refreshHeaders(String refreshToken) =>
      <String, dynamic>{
        AppApi.authorizationHeader: '${AppApi.bearerPrefix} $refreshToken',
      };

  @override
  Future<AuthResponseModel> register(RegisterRequestModel request) async {
    final Object? json = await _client.post(
      AppApi.register,
      data: request.toJson(),
    );
    return AuthResponseModel.fromJson(asJsonObject(json));
  }

  @override
  Future<AuthResponseModel> login(LoginRequestModel request) async {
    final Object? json = await _client.post(
      AppApi.login,
      data: request.toJson(),
    );
    return AuthResponseModel.fromJson(asJsonObject(json));
  }

  @override
  Future<AuthResponseModel> refresh(String refreshToken) async {
    final Object? json = await _client.post(
      AppApi.refresh,
      headers: _refreshHeaders(refreshToken),
    );
    return AuthResponseModel.fromJson(asJsonObject(json));
  }

  @override
  Future<void> logout(String refreshToken) async {
    await _client.post(AppApi.logout, headers: _refreshHeaders(refreshToken));
  }

  @override
  Future<AcceptedResponseModel> requestPasswordReset(
    PasswordResetRequestModel request,
  ) async {
    final Object? json = await _client.post(
      AppApi.passwordResetRequest,
      data: request.toJson(),
    );
    return AcceptedResponseModel.fromJson(asJsonObject(json));
  }

  @override
  Future<void> confirmPasswordReset(
    PasswordResetConfirmRequestModel request,
  ) async {
    await _client.post(AppApi.passwordResetConfirm, data: request.toJson());
  }
}
