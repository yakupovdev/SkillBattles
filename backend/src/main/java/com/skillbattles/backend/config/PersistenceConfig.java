package com.skillbattles.backend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.auditing.DateTimeProvider;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import java.time.Clock;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.Optional;

@Configuration
@EnableJpaAuditing(dateTimeProviderRef = "utcDateTimeProvider")
public class PersistenceConfig {
    @Bean
    public Clock clock() { return Clock.systemUTC(); }

    @Bean
    public DateTimeProvider utcDateTimeProvider(Clock clock) {
        return () -> Optional.of(LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC));
    }
}
