// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_code_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FriendCodeModel _$FriendCodeModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FriendCodeModel', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['friendCode']);
      final val = FriendCodeModel(
        friendCode: $checkedConvert('friendCode', (v) => _canonicalCode(v)),
      );
      return val;
    });
