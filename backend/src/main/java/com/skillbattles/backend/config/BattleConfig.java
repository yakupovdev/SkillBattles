package com.skillbattles.backend.config;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Profile;
import com.skillbattles.backend.service.*;

@Configuration
@EnableConfigurationProperties(BattleProperties.class)
public class BattleConfig {
    @Bean
    @Profile("question-import")
    public PresenceService importPresenceService() { return userId -> java.util.Optional.empty(); }
}
