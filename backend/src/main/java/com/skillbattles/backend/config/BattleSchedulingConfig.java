package com.skillbattles.backend.config;

import com.skillbattles.backend.scheduler.BattleScheduler;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.*;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.concurrent.ThreadPoolTaskScheduler;
import java.time.Clock;

@Configuration
@Profile("!question-import")
@EnableScheduling
@ConditionalOnProperty(name = "app.battle.scheduling.enabled", havingValue = "true", matchIfMissing = true)
@Import(BattleScheduler.class)
public class BattleSchedulingConfig {
    @Bean
    public ThreadPoolTaskScheduler taskScheduler(Clock clock) {
        // Database polling must not delay transport heartbeats or JWT expiry.
        ThreadPoolTaskScheduler scheduler = new ThreadPoolTaskScheduler();
        scheduler.setClock(clock);
        scheduler.setPoolSize(1);
        scheduler.setThreadNamePrefix("battle-timer-");
        scheduler.setRemoveOnCancelPolicy(true);
        return scheduler;
    }
}
