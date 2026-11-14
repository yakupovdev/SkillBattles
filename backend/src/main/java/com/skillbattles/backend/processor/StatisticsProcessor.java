package com.skillbattles.backend.processor;

import com.skillbattles.backend.dto.StatisticsDto;
import java.util.UUID;

public interface StatisticsProcessor {
    StatisticsDto getForUser(UUID userId);
}
