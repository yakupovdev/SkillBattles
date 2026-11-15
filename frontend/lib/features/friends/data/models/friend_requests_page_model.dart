import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/pagination_model.dart';
import 'package:skill_battles/features/friends/data/models/relationship_model.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_requests_page_entity.dart';

part 'friend_requests_page_model.g.dart';

/// FriendRequestsPage (PENDING only).
@JsonSerializable(checked: true, createToJson: false)
final class FriendRequestsPageModel {
  const FriendRequestsPageModel({required this.data, required this.pagination});

  factory FriendRequestsPageModel.fromJson(Map<String, dynamic> json) =>
      _$FriendRequestsPageModelFromJson(json);

  @JsonKey(required: true)
  final List<RelationshipModel> data;

  @JsonKey(required: true)
  final PaginationModel pagination;

  FriendRequestsPageEntity toEntity({required String viewerId}) =>
      FriendRequestsPageEntity(
        items: data
            .map((RelationshipModel item) => item.toEntity(viewerId: viewerId))
            .toList(growable: false),
        page: pagination.toEntity(),
      );
}
