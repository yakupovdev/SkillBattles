import 'package:skill_battles/core/domain/entity/battle_mode.dart';
import 'package:skill_battles/core/domain/entity/battle_outcome.dart';
import 'package:skill_battles/core/domain/entity/battle_reason.dart';
import 'package:skill_battles/core/domain/entity/page_info_entity.dart';
import 'package:skill_battles/core/domain/entity/public_player_entity.dart';
import 'package:skill_battles/core/presentation/skeleton/skeletonizer.dart';
import 'package:skill_battles/features/history/domain/entity/history_item_entity.dart';
import 'package:skill_battles/features/history/domain/entity/history_page_entity.dart';

/// Mock history rendered as bones while the first page loads.
final class HistorySkeletonData {
  HistorySkeletonData._();

  static final HistoryPageEntity page = HistoryPageEntity(
    items: <HistoryItemEntity>[
      for (int i = 0; i < 5; i++)
        HistoryItemEntity(
          battleId: 'skeleton-$i',
          disciplineCode: 'SAT_MATH',
          mode: BattleMode.ranked,
          outcome: BattleOutcome.win,
          reason: BattleReason.normal,
          opponent: PublicPlayerEntity(
            id: 'skeleton-$i',
            nickname: BoneMock.name,
            isPro: false,
          ),
          myScore: 4200,
          opponentScore: 3100,
          ratingDelta: 16,
          seasonId: null,
          overtimePlayed: false,
          createdAt: DateTime.utc(2026),
          finishedAt: DateTime.utc(2026),
        ),
    ],
    page: const PageInfoEntity(
      page: 0,
      size: 10,
      totalElements: 5,
      totalPages: 1,
    ),
    historyLimit: null,
  );
}
