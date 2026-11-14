package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.*;
import java.time.Instant;
import java.util.*;

/** Pure state transitions. The caller serializes access and persists/settles in one transaction. */
public interface BattleEngine {
    void advance(BattleDto battle, Instant now);
    void synchronizePresence(BattleDto battle, Map<UUID, PresenceDto> presence, Instant now);
    void ready(BattleDto battle, UUID userId, Instant now);
    AnswerReceiptDto answer(BattleDto battle, UUID userId, AnswerDto answer, Instant receivedAt, Instant now);
    void surrender(BattleDto battle, UUID userId, Instant now);
    void interrupt(BattleDto battle, Instant now);
}
