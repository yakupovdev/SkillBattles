import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/public_player_entity.dart';

/// A row with a unique position (rating desc, reached-at asc, id asc).
final class LeaderboardEntryEntity extends Equatable {
  const LeaderboardEntryEntity({
    required this.position,
    required this.player,
    required this.rating,
    required this.rankCode,
    required this.isCalibrating,
  });

  final int position;
  final PublicPlayerEntity player;
  final int rating;
  final String rankCode;
  final bool isCalibrating;

  @override
  List<Object?> get props => <Object?>[
    position,
    player,
    rating,
    rankCode,
    isCalibrating,
  ];
}
