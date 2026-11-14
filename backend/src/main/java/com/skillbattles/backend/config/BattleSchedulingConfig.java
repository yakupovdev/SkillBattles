package com.skillbattles.backend.config;

import com.skillbattles.backend.scheduler.BattleScheduler;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.*;
import org.springframework.scheduling.annotation.EnableScheduling;

@Configuration
@Profile("!question-import")
@EnableScheduling
@ConditionalOnProperty(name = "app.battle.scheduling.enabled", havingValue = "true", matchIfMissing = true)
@Import(BattleScheduler.class)
public class BattleSchedulingConfig { }
