import 'package:equatable/equatable.dart';

import 'package:skill_battles/features/account/domain/entity/calibration_entity.dart';
import 'package:skill_battles/features/account/domain/entity/match_stats_entity.dart';
import 'package:skill_battles/features/account/domain/entity/rank_progress_entity.dart';
import 'package:skill_battles/features/account/domain/entity/rating_history_point_entity.dart';
import 'package:skill_battles/features/account/domain/entity/topic_stats_entity.dart';

/// Rating and statistics of one discipline.
///
/// [topicStats] and [ratingHistory] are `null` when the plan does not include
/// advanced analytics — that is a Pro restriction, not missing progress.
final class DisciplineStatsEntity extends Equatable {
  const DisciplineStatsEntity({
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

  final String disciplineCode;
  final int rating;
  final RankProgressEntity rank;
  final CalibrationEntity calibration;
  final int allTimePeakRating;
  final String allTimePeakRankCode;
  final String seasonId;
  final int seasonPeakRating;
  final String seasonPeakRankCode;

  /// An old-season match must settle before this rating is reset.
  final bool seasonRolloverPending;
  final MatchStatsEntity ranked;
  final MatchStatsEntity privateMatches;
  final List<TopicStatsEntity>? topicStats;
  final List<RatingHistoryPointEntity>? ratingHistory;

  @override
  List<Object?> get props => <Object?>[
    disciplineCode,
    rating,
    rank,
    calibration,
    allTimePeakRating,
    allTimePeakRankCode,
    seasonId,
    seasonPeakRating,
    seasonPeakRankCode,
    seasonRolloverPending,
    ranked,
    privateMatches,
    topicStats,
    ratingHistory,
  ];
}
