package com.skillbattles.backend.scheduler;

import com.skillbattles.backend.processor.MatchmakingProcessor;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;

@Slf4j
@RequiredArgsConstructor
public class MatchmakingScheduler {
    private final MatchmakingProcessor processor;
    private final BattleRecovery recovery;
    @Scheduled(fixedDelayString = "${app.matchmaking.scheduling.poll-ms:500}", scheduler = "matchmakingTaskScheduler")
    public void poll() {
        if (!recovery.isReady()) return;
        try { processor.poll(); }
        catch (RuntimeException ex) { log.error("Matchmaking poll failed: {}", ex.getClass().getSimpleName()); }
    }
}
