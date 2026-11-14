package com.skillbattles.backend.repository;

import com.skillbattles.backend.dto.BattleResultDataDto;
import com.skillbattles.backend.entity.*;
import java.time.LocalDateTime;
import java.util.UUID;

/** Metadata and persisted result only: question/round state is not loaded for history. */
public interface BattleHistoryProjection {
    UUID getBattleId();
    Subject getSubject();
    BattleMode getMode();
    BattlePhase getPhase();
    LocalDateTime getCreatedAt();
    BattleResultDataDto getResult();
}
