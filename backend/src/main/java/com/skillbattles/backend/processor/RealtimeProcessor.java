package com.skillbattles.backend.processor;

import com.skillbattles.backend.dto.*;

public interface RealtimeProcessor {
    void presenceChanged(PresenceChangedEvent event);
    void battleChanged(BattleChangedEvent event);
    void activityChanged(ActivityChangedEvent event);
}
