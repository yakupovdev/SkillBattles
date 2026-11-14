package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.*;
import java.time.Instant;
import java.util.UUID;
public interface BattleAccessProcessor {
    void require(BattleDto battle,UUID userId);
    BattleSnapshotDto snapshot(BattleDto battle,UUID userId,Instant at);
    BattleResultDto result(BattleDto battle,UUID userId);
    BattleReviewDto review(BattleDto battle,UUID userId);
    BattleHistoryPage history(BattleHistoryQueryDto query);
}
