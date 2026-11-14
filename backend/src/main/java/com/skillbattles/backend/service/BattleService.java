package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.*;
import java.util.*;

public interface BattleService {
    BattleDto create(BattleDto dto);
    BattleDto lock(UUID id);
    BattleDto getForParticipant(UUID id, UUID userId);
    PageResponse<BattleHistoryItemDto> history(BattleHistoryQueryDto query);
    PageResponse<BattleHistoryItemDto> history(BattleHistoryQueryDto query,Integer limit);
    List<UUID> recentTerminal(UUID userId,int limit);
    void save(BattleDto dto);
    boolean hasActiveBattle(UUID userId);
    boolean hasActiveRankedBattle(UUID userId,String code);
    List<UUID> activeIds();
    List<UUID> activeIdsForUser(UUID userId);
    List<BattleCountsDto> statistics(UUID userId);
    List<QuestionSeenDto> recentQuestionShows(UUID userId, String disciplineCode, int battleLimit);
}
