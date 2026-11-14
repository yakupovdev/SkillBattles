import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/core/domain/entity/entitlements_entity.dart';
import 'package:skill_battles/features/account/domain/entity/calibration_entity.dart';
import 'package:skill_battles/features/account/domain/entity/discipline_stats_entity.dart';
import 'package:skill_battles/features/account/domain/entity/match_stats_entity.dart';
import 'package:skill_battles/features/account/domain/entity/rank_progress_entity.dart';
import 'package:skill_battles/features/account/domain/entity/statistics_entity.dart';
import 'package:skill_battles/features/account/domain/entity/streaks_entity.dart';
import 'package:skill_battles/features/catalog/domain/entity/difficulty_schedule_entity.dart';
import 'package:skill_battles/features/catalog/domain/entity/difficulty_timing_entity.dart';
import 'package:skill_battles/features/catalog/domain/entity/discipline_entity.dart';

/// Mock entities rendered as bones while the profile loads. Never
/// reaches a BLoC or a repository.
final class ProfileSkeletonData {
  ProfileSkeletonData._();

  static final List<DisciplineEntity> disciplines = <DisciplineEntity>[
    for (int i = 0; i < 2; i++)
      DisciplineEntity(
        code: 'skeleton-$i',
        displayName: BoneMock.chars(9),
        description: BoneMock.words(4),
        questionCount: 5,
        baseQuestionSeconds: 60,
        timings: const <DifficultyTimingEntity>[],
        schedules: const <DifficultyScheduleEntity>[],
        overtimeSeconds: 30,
        readyTimeoutSeconds: 30,
        countdownSeconds: 3,
        revealSeconds: 5,
        reconnectGraceSeconds: 30,
        contentAvailable: true,
      ),
  ];

  static const MatchStatsEntity _stats = MatchStatsEntity(
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

  static final StatisticsEntity statistics = StatisticsEntity(
    entitlements: const EntitlementsEntity(
      isPro: false,
      version: 0,
      unlimitedRanked: false,
      historyMatchLimit: 10,
      canViewCorrectAnswers: false,
      canViewExplanations: false,
      canViewAdvancedAnalytics: false,
      canFilterMistakes: false,
    ),
    streaks: StreaksEntity(
      dailyCurrent: 3,
      dailyBest: 7,
      lastQualifiedDate: null,
      weeklyCurrent: 1,
      weeklyBest: 2,
      currentWeekStart: DateTime.utc(2026),
      currentWeekActiveDays: 2,
      currentWeekTarget: 4,
    ),
    disciplines: <DisciplineStatsEntity>[
      for (int i = 0; i < 2; i++)
        DisciplineStatsEntity(
          disciplineCode: 'skeleton-$i',
          rating: 1032,
          rank: RankProgressEntity(
            rankCode: 'SILVER_I',
            rankName: BoneMock.chars(8),
            leagueCode: 'SILVER',
            divisionRpCurrent: 32,
            divisionRpTarget: 100,
            floorRating: 1000,
            ceilingExclusive: 1100,
          ),
          calibration: const CalibrationEntity(
            completedMatches: 5,
            matchesRemaining: 0,
            isCalibrating: false,
            nextKFactor: 32,
          ),
          allTimePeakRating: 1100,
          allTimePeakRankCode: 'SILVER_II',
          seasonId: 'skeleton',
          seasonPeakRating: 1080,
          seasonPeakRankCode: 'SILVER_I',
          seasonRolloverPending: false,
          ranked: _stats,
          privateMatches: _stats,
          topicStats: null,
          ratingHistory: null,
        ),
    ],
  );
}
