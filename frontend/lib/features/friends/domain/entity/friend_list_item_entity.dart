import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/public_player_entity.dart';

/// One accepted friend. [friend] `.id` is the USER id used by the profile,
/// remove and invite calls; [relationshipId] identifies the friendship.
final class FriendListItemEntity extends Equatable {
  const FriendListItemEntity({
    required this.relationshipId,
    required this.friend,
    required this.friendsSince,
    required this.version,
  });

  final String relationshipId;
  final PublicPlayerEntity friend;
  final DateTime friendsSince;
  final int version;

  @override
  List<Object?> get props => <Object?>[
    relationshipId,
    friend,
    friendsSince,
    version,
  ];
}
