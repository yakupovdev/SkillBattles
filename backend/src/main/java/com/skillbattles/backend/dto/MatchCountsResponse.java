package com.skillbattles.backend.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class MatchCountsResponse {
    private int wins;
    private int losses;
    private int draws;
    private int played;
    @io.swagger.v3.oas.annotations.media.Schema(nullable=true) private Double winRatePercent;
    private int currentWinStreak;
    private int bestWinStreak;
    @io.swagger.v3.oas.annotations.media.Schema(nullable=true) private Double accuracyPercent;
    @io.swagger.v3.oas.annotations.media.Schema(nullable=true) private Long avgAnswerTimeMs;
    private int questionCount;

}
