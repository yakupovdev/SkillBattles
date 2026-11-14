package com.skillbattles.backend.scheduler;

import com.skillbattles.backend.processor.BattleProcessor;
import com.skillbattles.backend.service.BattleService;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.*;
import org.springframework.context.annotation.Profile;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

@Component
@Profile("!question-import")
@Order(Ordered.HIGHEST_PRECEDENCE)
@RequiredArgsConstructor
public class BattleRecovery implements ApplicationRunner {
    private final BattleService battles;
    private final BattleProcessor processor;
    private volatile boolean ready;

    @Override public void run(ApplicationArguments args) { recover(); }

    public void recover() {
        for (var id : battles.activeIds()) processor.interrupt(id);
        ready = true;
    }

    public boolean isReady() { return ready; }
}
