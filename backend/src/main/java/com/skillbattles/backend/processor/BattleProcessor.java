package com.skillbattles.backend.processor;

import com.skillbattles.backend.dto.*;
import java.time.Instant;
import java.util.UUID;

public interface BattleProcessor {
    UUID create(CreateBattleDto command);
    BattleSnapshotDto snapshot(UUID battleId, UUID userId);
    BattleSnapshotDto ready(UUID battleId, UUID userId);
    AnswerReceiptDto answer(UUID battleId, UUID userId, AnswerDto answer, Instant receivedAt);
    BattleSnapshotDto surrender(UUID battleId, UUID userId);
    BattleResultDto result(UUID battleId, UUID userId);
    void tick(UUID battleId);
    void interrupt(UUID battleId);
}
