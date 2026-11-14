package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.*;
import java.time.Instant;
import java.util.UUID;
public interface UsageProcessor {
    LimitsDto limits(UUID userId);
    LimitsDto limits(UUID userId,SubscriptionDto subscription);
    void requireAvailable(UUID userId);
    boolean start(BattleDto battle,Instant at);
    void finish(BattleDto battle);
}
