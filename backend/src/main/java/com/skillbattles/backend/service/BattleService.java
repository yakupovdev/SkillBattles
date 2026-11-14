package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.Subject;
import java.util.*;

public interface BattleService {
    BattleDto create(BattleDto dto);
    BattleDto lock(UUID id);
    BattleDto getForParticipant(UUID id, UUID userId);
    PageResponse<BattleHistoryItemDto> history(BattleHistoryQueryDto query);
    void save(BattleDto dto);
    boolean hasActiveBattle(UUID userId);
    List<UUID> activeIds();
    List<UUID> activeIdsForUser(UUID userId);
    List<BattleCountsDto> statistics(UUID userId);
    List<QuestionSeenDto> recentQuestionShows(UUID userId, Subject subject, int battleLimit);
}
