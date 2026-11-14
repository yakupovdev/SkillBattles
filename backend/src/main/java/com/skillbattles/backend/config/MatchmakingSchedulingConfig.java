package com.skillbattles.backend.config;

import com.skillbattles.backend.scheduler.MatchmakingScheduler;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.*;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.concurrent.ThreadPoolTaskScheduler;
import java.time.Clock;

@Configuration
@Profile("!question-import")
@EnableScheduling
@ConditionalOnProperty(name = "app.matchmaking.scheduling.enabled", havingValue = "true", matchIfMissing = true)
@Import(MatchmakingScheduler.class)
public class MatchmakingSchedulingConfig {
    @Bean public ThreadPoolTaskScheduler matchmakingTaskScheduler(Clock clock) {
        ThreadPoolTaskScheduler scheduler = new ThreadPoolTaskScheduler();
        scheduler.setClock(clock); scheduler.setPoolSize(1); scheduler.setThreadNamePrefix("matchmaking-");
        return scheduler;
    }
}
