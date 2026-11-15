import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/public_player_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_discipline_stats_entity.dart';

/// Server-redacted profile of an accepted friend.
final class FriendProfileEntity extends Equatable {
  const FriendProfileEntity({
    required this.friend,
    required this.friendsSince,
    required this.disciplines,
  });

  final PublicPlayerEntity friend;
  final DateTime friendsSince;
  final List<FriendDisciplineStatsEntity> disciplines;

  @override
  List<Object?> get props => <Object?>[friend, friendsSince, disciplines];
}
