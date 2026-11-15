// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_list_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FriendListItemModel _$FriendListItemModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FriendListItemModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'relationshipId',
          'friend',
          'friendsSince',
          'version',
        ],
      );
      final val = FriendListItemModel(
        relationshipId: $checkedConvert('relationshipId', (v) => v as String),
        friend: $checkedConvert(
          'friend',
          (v) => PublicPlayerModel.fromJson(v as Map<String, dynamic>),
        ),
        friendsSince: $checkedConvert(
          'friendsSince',
          (v) => DateTime.parse(v as String),
        ),
        version: $checkedConvert('version', (v) => (v as num).toInt()),
      );
      return val;
    });
