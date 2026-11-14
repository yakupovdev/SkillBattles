package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.Subject;
import java.util.*;

public interface BattleService {
    BattleDto create(BattleDto dto);
    BattleDto lock(UUID id);
    void save(BattleDto dto);
    boolean hasActiveBattle(UUID userId);
    List<UUID> activeIds();
    List<BattleCountsDto> statistics(UUID userId);
    List<QuestionSeenDto> recentQuestionShows(UUID userId, Subject subject, int battleLimit);
}
