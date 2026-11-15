import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/public_player_model.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_list_item_entity.dart';

part 'friend_list_item_model.g.dart';

/// One accepted friend.
@JsonSerializable(checked: true, createToJson: false)
final class FriendListItemModel {
  const FriendListItemModel({
    required this.relationshipId,
    required this.friend,
    required this.friendsSince,
    required this.version,
  });

  factory FriendListItemModel.fromJson(Map<String, dynamic> json) =>
      _$FriendListItemModelFromJson(json);

  @JsonKey(required: true)
  final String relationshipId;

  @JsonKey(required: true)
  final PublicPlayerModel friend;

  @JsonKey(required: true)
  final DateTime friendsSince;

  @JsonKey(required: true)
  final int version;

  FriendListItemEntity toEntity() => FriendListItemEntity(
    relationshipId: relationshipId,
    friend: friend.toEntity(),
    friendsSince: friendsSince,
    version: version,
  );
}
