import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/calibration_entity.dart';
import 'package:skill_battles/core/domain/entity/match_stats_entity.dart';
import 'package:skill_battles/core/domain/entity/rank_progress_entity.dart';

/// Basic per-discipline statistics of a friend. The field set is the same
/// for every plan: no topics, rating history or answers.
final class FriendDisciplineStatsEntity extends Equatable {
  const FriendDisciplineStatsEntity({
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

  /// Counters over all settled matches; `null` values mean no data yet.
  final MatchStatsEntity ranked;
  final MatchStatsEntity privateMatches;

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
  ];
}
