// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_profile_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateProfileResponseModel _$UpdateProfileResponseModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('UpdateProfileResponseModel', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['user', 'passwordChanged', 'reauthenticationRequired'],
  );
  final val = UpdateProfileResponseModel(
    user: $checkedConvert(
      'user',
      (v) => UserModel.fromJson(v as Map<String, dynamic>),
    ),
    passwordChanged: $checkedConvert('passwordChanged', (v) => v as bool),
    reauthenticationRequired: $checkedConvert(
      'reauthenticationRequired',
      (v) => v as bool,
    ),
  );
  return val;
});
