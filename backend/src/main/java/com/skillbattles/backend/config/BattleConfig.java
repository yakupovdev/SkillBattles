package com.skillbattles.backend.config;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Bean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import com.skillbattles.backend.service.*;

@Configuration
@EnableConfigurationProperties(BattleProperties.class)
public class BattleConfig {
    @Bean
    @ConditionalOnMissingBean(PresenceService.class)
    public PresenceService presenceService() { return new PresenceServiceImpl(); }
}
