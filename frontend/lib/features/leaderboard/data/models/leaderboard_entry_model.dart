import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/public_player_model.dart';
import 'package:skill_battles/features/leaderboard/domain/entity/leaderboard_entry_entity.dart';

part 'leaderboard_entry_model.g.dart';

/// One leaderboard row.
@JsonSerializable(checked: true, createToJson: false)
final class LeaderboardEntryModel {
  const LeaderboardEntryModel({
    required this.position,
    required this.player,
    required this.rating,
    required this.rankCode,
    required this.isCalibrating,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardEntryModelFromJson(json);

  @JsonKey(required: true)
  final int position;

  @JsonKey(required: true)
  final PublicPlayerModel player;

  @JsonKey(required: true)
  final int rating;

  @JsonKey(required: true)
  final String rankCode;

  @JsonKey(required: true)
  final bool isCalibrating;

  LeaderboardEntryEntity toEntity() => LeaderboardEntryEntity(
    position: position,
    player: player.toEntity(),
    rating: rating,
    rankCode: rankCode,
    isCalibrating: isCalibrating,
  );
}
