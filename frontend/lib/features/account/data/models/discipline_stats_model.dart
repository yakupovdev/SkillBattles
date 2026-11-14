import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/account/data/models/calibration_model.dart';
import 'package:skill_battles/features/account/data/models/match_stats_model.dart';
import 'package:skill_battles/features/account/data/models/rank_progress_model.dart';
import 'package:skill_battles/features/account/data/models/rating_history_point_model.dart';
import 'package:skill_battles/features/account/data/models/topic_stats_model.dart';
import 'package:skill_battles/features/account/domain/entity/discipline_stats_entity.dart';

part 'discipline_stats_model.g.dart';

/// Rating and statistics of one discipline; advanced arrays are null for Free.
@JsonSerializable(checked: true, createToJson: false)
final class DisciplineStatsModel {
  const DisciplineStatsModel({
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
    required this.topicStats,
    required this.ratingHistory,
  });

  factory DisciplineStatsModel.fromJson(Map<String, dynamic> json) =>
      _$DisciplineStatsModelFromJson(json);

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

  @JsonKey(required: true)
  final List<TopicStatsModel>? topicStats;

  @JsonKey(required: true)
  final List<RatingHistoryPointModel>? ratingHistory;

  DisciplineStatsEntity toEntity() => DisciplineStatsEntity(
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
    topicStats: topicStats
        ?.map((TopicStatsModel topic) => topic.toEntity())
        .toList(growable: false),
    ratingHistory: ratingHistory
        ?.map((RatingHistoryPointModel point) => point.toEntity())
        .toList(growable: false),
  );
}
