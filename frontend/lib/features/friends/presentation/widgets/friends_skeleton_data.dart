import 'package:skill_battles/core/domain/entity/calibration_entity.dart';
import 'package:skill_battles/core/domain/entity/match_stats_entity.dart';
import 'package:skill_battles/core/domain/entity/page_info_entity.dart';
import 'package:skill_battles/core/domain/entity/public_player_entity.dart';
import 'package:skill_battles/core/domain/entity/rank_progress_entity.dart';
import 'package:skill_battles/core/presentation/skeleton/skeletonizer.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_code_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_discipline_stats_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_list_item_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_profile_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_request_direction.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_requests_page_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friends_page_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_status.dart';

/// Mock entities rendered as bones while the Friends page and a friend
/// profile load. Never reaches a BLoC or a repository.
final class FriendsSkeletonData {
  FriendsSkeletonData._();

  static const FriendCodeEntity friendCode = FriendCodeEntity(
    code: 'K7QMX4N2WRTB',
  );

  static final DateTime _since = DateTime.utc(2026, 5, 12);

  static PublicPlayerEntity _player(int i) => PublicPlayerEntity(
    id: 'skeleton-$i',
    nickname: BoneMock.name,
    isPro: false,
  );

  static final FriendsPageEntity friends = FriendsPageEntity(
    items: <FriendListItemEntity>[
      for (int i = 0; i < 5; i++)
        FriendListItemEntity(
          relationshipId: 'skeleton-$i',
          friend: _player(i),
          friendsSince: _since,
          version: 0,
        ),
    ],
    page: const PageInfoEntity(
      page: 0,
      size: 20,
      totalElements: 5,
      totalPages: 1,
    ),
  );

  static FriendRequestsPageEntity requests(FriendRequestDirection direction) => FriendRequestsPageEntity(
    items: <RelationshipEntity>[
      for (int i = 0; i < 3; i++)
        RelationshipEntity(
          id: 'skeleton-$i',
          requester: _player(i),
          recipient: _player(i + 10),
          status: RelationshipStatus.pending,
          createdAt: _since,
          updatedAt: _since,
          acceptedAt: null,
          version: 0,
          direction: direction,
        ),
    ],
    page: const PageInfoEntity(
      page: 0,
      size: 20,
      totalElements: 3,
      totalPages: 1,
    ),
  );

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

  static final FriendProfileEntity profile = FriendProfileEntity(
    friend: _player(0),
    friendsSince: _since,
    disciplines: <FriendDisciplineStatsEntity>[
      for (int i = 0; i < 2; i++)
        FriendDisciplineStatsEntity(
          disciplineCode: 'SKELETON_$i',
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
        ),
    ],
  );
}
