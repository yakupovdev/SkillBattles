package com.skillbattles.backend.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class MatchCountsDto {
    private int wins;
    private int losses;
    private int draws;
    private int played;
    private Double winRatePercent;
    private int currentWinStreak;
    private int bestWinStreak;
    private Double accuracyPercent;
    private Long avgAnswerTimeMs;
    private int questionCount;

}
