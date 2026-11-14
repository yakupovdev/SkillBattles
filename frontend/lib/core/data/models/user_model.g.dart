// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UserModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['id', 'email', 'nickname', 'createdAt', 'isPro'],
      );
      final val = UserModel(
        id: $checkedConvert('id', (v) => v as String),
        email: $checkedConvert('email', (v) => v as String),
        nickname: $checkedConvert('nickname', (v) => v as String),
        createdAt: $checkedConvert(
          'createdAt',
          (v) => DateTime.parse(v as String),
        ),
        isPro: $checkedConvert('isPro', (v) => v as bool),
      );
      return val;
    });
