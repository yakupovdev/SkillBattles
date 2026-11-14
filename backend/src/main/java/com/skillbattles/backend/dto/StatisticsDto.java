package com.skillbattles.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import java.util.List;

@Getter
@AllArgsConstructor
public class StatisticsDto {
    private final List<DisciplineStatisticsDto> disciplines;
    private final EntitlementsDto entitlements;
    private final StreaksDto streaks;
}
