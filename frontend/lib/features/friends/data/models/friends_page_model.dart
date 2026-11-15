import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/pagination_model.dart';
import 'package:skill_battles/features/friends/data/models/friend_list_item_model.dart';
import 'package:skill_battles/features/friends/domain/entity/friends_page_entity.dart';

part 'friends_page_model.g.dart';

/// FriendsPage.
@JsonSerializable(checked: true, createToJson: false)
final class FriendsPageModel {
  const FriendsPageModel({required this.data, required this.pagination});

  factory FriendsPageModel.fromJson(Map<String, dynamic> json) =>
      _$FriendsPageModelFromJson(json);

  @JsonKey(required: true)
  final List<FriendListItemModel> data;

  @JsonKey(required: true)
  final PaginationModel pagination;

  FriendsPageEntity toEntity() => FriendsPageEntity(
    items: data
        .map((FriendListItemModel item) => item.toEntity())
        .toList(growable: false),
    page: pagination.toEntity(),
  );
}
