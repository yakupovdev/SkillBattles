package com.skillbattles.backend.repository;

import com.skillbattles.backend.entity.*;

public interface BattleStatisticsProjection {
    String getDisciplineCode();
    BattleMode getMode();
    long getWins();
    long getLosses();
    long getDraws();
    long getPlayed();
}
