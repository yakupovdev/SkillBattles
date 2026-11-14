package com.skillbattles.backend.config;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.*;
import org.springframework.scheduling.concurrent.ThreadPoolTaskScheduler;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;
import java.time.Clock;

@Configuration
@Profile("!question-import")
@EnableConfigurationProperties(RealtimeProperties.class)
public class RealtimeSchedulingConfig {
    @Bean
    public ThreadPoolTaskScheduler realtimeTaskScheduler(Clock clock) {
        ThreadPoolTaskScheduler scheduler = new ThreadPoolTaskScheduler();
        scheduler.setClock(clock);
        scheduler.setPoolSize(2);
        scheduler.setThreadNamePrefix("realtime-");
        scheduler.setRemoveOnCancelPolicy(true);
        return scheduler;
    }

    @Bean
    public ThreadPoolTaskExecutor realtimeEventExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(2);
        executor.setMaxPoolSize(4);
        executor.setQueueCapacity(256);
        executor.setThreadNamePrefix("realtime-events-");
        executor.setWaitForTasksToCompleteOnShutdown(true);
        executor.setAwaitTerminationSeconds(5);
        return executor;
    }
}
