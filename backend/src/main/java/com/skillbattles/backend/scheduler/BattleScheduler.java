package com.skillbattles.backend.scheduler;

import com.skillbattles.backend.processor.BattleProcessor;
import com.skillbattles.backend.service.BattleService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;

@Slf4j
@RequiredArgsConstructor
public class BattleScheduler {
    private final BattleService battles;
    private final BattleProcessor processor;
    private final BattleRecovery recovery;

    @Scheduled(fixedDelayString = "${app.battle.scheduling.poll-ms:500}")
    public void poll() {
        if (!recovery.isReady()) return;
        for (var id : battles.activeIds()) {
            try { processor.tick(id); }
            catch (RuntimeException ex) { log.error("Battle tick failed for {}: {}", id, ex.getClass().getSimpleName()); }
        }
    }
}
