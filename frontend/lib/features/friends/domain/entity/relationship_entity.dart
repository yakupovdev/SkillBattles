import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/public_player_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_request_direction.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_status.dart';

/// A friend request / friendship record. [id] is the relationship id, never
/// a user id; a new request after a removal gets a new [id].
final class RelationshipEntity extends Equatable {
  const RelationshipEntity({
    required this.id,
    required this.requester,
    required this.recipient,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.acceptedAt,
    required this.version,
    required this.direction,
  });

  final String id;
  final PublicPlayerEntity requester;
  final PublicPlayerEntity recipient;
  final RelationshipStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// `null` until accepted.
  final DateTime? acceptedAt;

  /// Monotonic per [id]; equals the realtime envelope version.
  final int version;

  /// Resolved against the signed-in user when the record was read.
  final FriendRequestDirection direction;

  bool get isIncoming => direction == FriendRequestDirection.incoming;

  /// The player on the other side of the record.
  PublicPlayerEntity get otherPlayer => isIncoming ? requester : recipient;

  /// Only the recipient may accept or decline a pending request.
  bool get canRespond => status.isPending && isIncoming;

  /// Only the requester may cancel a pending request.
  bool get canCancel => status.isPending && !isIncoming;

  @override
  List<Object?> get props => <Object?>[
    id,
    requester,
    recipient,
    status,
    createdAt,
    updatedAt,
    acceptedAt,
    version,
    direction,
  ];
}
