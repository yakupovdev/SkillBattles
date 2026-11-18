import 'package:skill_battles/core/domain/entity/calibration_entity.dart';
import 'package:skill_battles/core/domain/entity/match_stats_entity.dart';
import 'package:skill_battles/core/domain/entity/public_player_entity.dart';
import 'package:skill_battles/core/domain/entity/rank_progress_entity.dart';
import 'package:skill_battles/core/domain/entity/season_entity.dart';
import 'package:skill_battles/core/presentation/skeleton/skeletonizer.dart';
import 'package:skill_battles/features/account/domain/entity/discipline_stats_entity.dart';
import 'package:skill_battles/features/leaderboard/domain/entity/leaderboard_entity.dart';
import 'package:skill_battles/features/leaderboard/domain/entity/leaderboard_entry_entity.dart';

/// Mock board rendered as bones while the leaderboard loads.
final class LeaderboardSkeletonData {
  LeaderboardSkeletonData._();

  static final LeaderboardEntity board = LeaderboardEntity(
    disciplineCode: 'skeleton',
    season: SeasonEntity(
      id: 'skeleton',
      name: BoneMock.chars(9),
      startsAt: DateTime.utc(2026, 9),
      endsAt: DateTime.utc(2026, 12),
    ),
    generatedAt: DateTime.utc(2026),
    top: <LeaderboardEntryEntity>[
      for (int i = 0; i < 6; i++)
        LeaderboardEntryEntity(
          position: i + 1,
          player: PublicPlayerEntity(
            id: 'skeleton-$i',
            nickname: BoneMock.name,
            isPro: false,
          ),
          rating: 2000 - i * 80,
          rankCode: 'PLATINUM_II',
          isCalibrating: false,
        ),
    ],
    me: null,
  );

  static const MatchStatsEntity _matches = MatchStatsEntity(
    wins: 12,
    losses: 9,
    draws: 1,
    played: 22,
    winRatePercent: 54.5,
    currentWinStreak: 2,
    bestWinStreak: 5,
    accuracyPercent: 71.2,
    avgAnswerTime: Duration(seconds: 21),
    questionCount: 110,
  );

  /// Own statistics of the side panel (league block and peaks).
  static final DisciplineStatsEntity stats = DisciplineStatsEntity(
    disciplineCode: 'skeleton',
    rating: 1960,
    rank: RankProgressEntity(
      rankCode: 'PLATINUM_II',
      rankName: BoneMock.chars(12),
      leagueCode: 'PLATINUM',
      divisionRpCurrent: 32,
      divisionRpTarget: 100,
      floorRating: 1900,
      ceilingExclusive: 2000,
    ),
    calibration: const CalibrationEntity(
      completedMatches: 5,
      matchesRemaining: 0,
      isCalibrating: false,
      nextKFactor: 32,
    ),
    allTimePeakRating: 2000,
    allTimePeakRankCode: 'PLATINUM_II',
    seasonId: 'skeleton',
    seasonPeakRating: 1980,
    seasonPeakRankCode: 'PLATINUM_II',
    seasonRolloverPending: false,
    ranked: _matches,
    privateMatches: _matches,
    topicStats: null,
    ratingHistory: null,
  );
}
