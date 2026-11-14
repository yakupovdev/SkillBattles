package com.skillbattles.backend.config;

import com.skillbattles.backend.processor.BattleModeProcessor;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.*;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

@Component @Order(Ordered.HIGHEST_PRECEDENCE + 1) @RequiredArgsConstructor
public class CatalogueStartup implements ApplicationRunner {
    private final BattleModeProcessor processor;
    @Override public void run(ApplicationArguments args) { processor.initializeActiveRatings(); }
}
