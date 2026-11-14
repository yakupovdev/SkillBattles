package com.skillbattles.backend.dto;

import lombok.Getter;
import lombok.Setter;
import java.util.List;

@Getter
@Setter
@io.swagger.v3.oas.annotations.media.Schema(requiredProperties={"disciplines","entitlements","streaks"})
public class StatisticsResponse {
    private List<DisciplineStatisticsResponse> disciplines;
    private Entitlements entitlements;
    private Streaks streaks;
}
