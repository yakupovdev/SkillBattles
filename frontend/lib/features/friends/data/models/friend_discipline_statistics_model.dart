import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/calibration_model.dart';
import 'package:skill_battles/core/data/models/match_stats_model.dart';
import 'package:skill_battles/core/data/models/rank_progress_model.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_discipline_stats_entity.dart';

part 'friend_discipline_statistics_model.g.dart';

/// FriendDisciplineStatistics: the basic subset of the account statistics,
/// without topic analytics or rating history.
@JsonSerializable(checked: true, createToJson: false)
final class FriendDisciplineStatisticsModel {
  const FriendDisciplineStatisticsModel({
    required this.disciplineCode,
    required this.rating,
    required this.rank,
    required this.calibration,
    required this.allTimePeakRating,
    required this.allTimePeakRankCode,
    required this.seasonId,
    required this.seasonPeakRating,
    required this.seasonPeakRankCode,
    required this.seasonRolloverPending,
    required this.ranked,
    required this.privateMatches,
  });

  factory FriendDisciplineStatisticsModel.fromJson(Map<String, dynamic> json) =>
      _$FriendDisciplineStatisticsModelFromJson(json);

  @JsonKey(required: true)
  final String disciplineCode;

  @JsonKey(required: true)
  final int rating;

  @JsonKey(required: true)
  final RankProgressModel rank;

  @JsonKey(required: true)
  final CalibrationModel calibration;

  @JsonKey(required: true)
  final int allTimePeakRating;

  @JsonKey(required: true)
  final String allTimePeakRankCode;

  @JsonKey(required: true)
  final String seasonId;

  @JsonKey(required: true)
  final int seasonPeakRating;

  @JsonKey(required: true)
  final String seasonPeakRankCode;

  @JsonKey(required: true)
  final bool seasonRolloverPending;

  @JsonKey(required: true)
  final MatchStatsModel ranked;

  @JsonKey(required: true)
  final MatchStatsModel privateMatches;

  FriendDisciplineStatsEntity toEntity() => FriendDisciplineStatsEntity(
    disciplineCode: disciplineCode,
    rating: rating,
    rank: rank.toEntity(),
    calibration: calibration.toEntity(),
    allTimePeakRating: allTimePeakRating,
    allTimePeakRankCode: allTimePeakRankCode,
    seasonId: seasonId,
    seasonPeakRating: seasonPeakRating,
    seasonPeakRankCode: seasonPeakRankCode,
    seasonRolloverPending: seasonRolloverPending,
    ranked: ranked.toEntity(),
    privateMatches: privateMatches.toEntity(),
  );
}
