import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/core/domain/entity/public_player_entity.dart';
import 'package:skill_battles/core/domain/entity/season_entity.dart';
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
}
