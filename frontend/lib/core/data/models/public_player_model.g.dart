// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_player_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicPlayerModel _$PublicPlayerModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PublicPlayerModel', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'nickname', 'isPro']);
      final val = PublicPlayerModel(
        id: $checkedConvert('id', (v) => v as String),
        nickname: $checkedConvert('nickname', (v) => v as String),
        isPro: $checkedConvert('isPro', (v) => v as bool),
      );
      return val;
    });
