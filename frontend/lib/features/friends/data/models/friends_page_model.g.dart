// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friends_page_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FriendsPageModel _$FriendsPageModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FriendsPageModel', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['data', 'pagination']);
      final val = FriendsPageModel(
        data: $checkedConvert(
          'data',
          (v) => (v as List<dynamic>)
              .map(
                (e) => FriendListItemModel.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
        pagination: $checkedConvert(
          'pagination',
          (v) => PaginationModel.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });
