// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_requests_page_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FriendRequestsPageModel _$FriendRequestsPageModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('FriendRequestsPageModel', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['data', 'pagination']);
  final val = FriendRequestsPageModel(
    data: $checkedConvert(
      'data',
      (v) => (v as List<dynamic>)
          .map((e) => RelationshipModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    pagination: $checkedConvert(
      'pagination',
      (v) => PaginationModel.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});
