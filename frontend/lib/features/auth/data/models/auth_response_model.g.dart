// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthResponseModel _$AuthResponseModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AuthResponseModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'accessToken',
          'refreshToken',
          'tokenType',
          'accessExpiresIn',
          'refreshExpiresIn',
          'user',
        ],
      );
      final val = AuthResponseModel(
        accessToken: $checkedConvert('accessToken', (v) => v as String),
        refreshToken: $checkedConvert('refreshToken', (v) => v as String),
        tokenType: $checkedConvert('tokenType', (v) => v as String),
        accessExpiresIn: $checkedConvert(
          'accessExpiresIn',
          (v) => (v as num).toInt(),
        ),
        refreshExpiresIn: $checkedConvert(
          'refreshExpiresIn',
          (v) => (v as num).toInt(),
        ),
        user: $checkedConvert(
          'user',
          (v) => UserModel.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });
