package com.skillbattles.backend.repository;

import com.skillbattles.backend.entity.*;

public interface BattleStatisticsProjection {
    Subject getSubject();
    BattleMode getMode();
    long getWins();
    long getLosses();
    long getDraws();
    long getPlayed();
}
