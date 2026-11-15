import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/public_player_model.dart';
import 'package:skill_battles/features/friends/data/models/relationship_status_model.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_request_direction.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_entity.dart';

part 'relationship_model.g.dart';

/// RelationshipResponse: a friend request / friendship record.
@JsonSerializable(checked: true, createToJson: false)
final class RelationshipModel {
  const RelationshipModel({
    required this.id,
    required this.requester,
    required this.recipient,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.acceptedAt,
    required this.version,
  });

  factory RelationshipModel.fromJson(Map<String, dynamic> json) =>
      _$RelationshipModelFromJson(json);

  @JsonKey(required: true)
  final String id;

  @JsonKey(required: true)
  final PublicPlayerModel requester;

  @JsonKey(required: true)
  final PublicPlayerModel recipient;

  @JsonKey(required: true)
  final RelationshipStatusModel status;

  @JsonKey(required: true)
  final DateTime createdAt;

  @JsonKey(required: true)
  final DateTime updatedAt;

  @JsonKey(required: true)
  final DateTime? acceptedAt;

  @JsonKey(required: true)
  final int version;

  /// [viewerId] is the signed-in user; it decides the request direction.
  RelationshipEntity toEntity({required String viewerId}) => RelationshipEntity(
    id: id,
    requester: requester.toEntity(),
    recipient: recipient.toEntity(),
    status: status.toEntity(),
    createdAt: createdAt,
    updatedAt: updatedAt,
    acceptedAt: acceptedAt,
    version: version,
    direction: recipient.id == viewerId
        ? FriendRequestDirection.incoming
        : FriendRequestDirection.outgoing,
  );
}
