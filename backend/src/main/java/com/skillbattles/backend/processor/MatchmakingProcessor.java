package com.skillbattles.backend.processor;

import com.skillbattles.backend.dto.*;
import java.util.UUID;

public interface MatchmakingProcessor {
    QueueEntryDto search(UUID userId, String disciplineCode);
    QueueEntryDto entry(UUID userId, UUID id);
    void cancelEntry(UUID userId, UUID id);
    DuelDto createDuel(UUID userId, String disciplineCode);
    DuelDto join(UUID userId, String code);
    DuelDto duel(UUID userId, UUID id);
    DuelDto present(DuelDto duel);
    void cancelDuel(UUID userId, UUID id);
    ActivityDto activity(UUID userId);
    void poll();
}
