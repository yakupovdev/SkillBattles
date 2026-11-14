package com.skillbattles.backend.processor;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.Subject;
import java.util.UUID;

public interface MatchmakingProcessor {
    QueueEntryDto search(UUID userId, Subject subject);
    QueueEntryDto entry(UUID userId, UUID id);
    void cancelEntry(UUID userId, UUID id);
    DuelDto createDuel(UUID userId, Subject subject);
    DuelDto join(UUID userId, String code);
    DuelDto duel(UUID userId, UUID id);
    void cancelDuel(UUID userId, UUID id);
    ActivityDto activity(UUID userId);
    void poll();
}
