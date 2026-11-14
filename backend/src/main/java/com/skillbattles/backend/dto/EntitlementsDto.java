package com.skillbattles.backend.dto;
import lombok.*;
import java.time.*;
import java.util.*;
@Data @NoArgsConstructor @AllArgsConstructor
public class EntitlementsDto {
    @com.fasterxml.jackson.annotation.JsonProperty("isPro") private boolean pro;
    private int version;
    private boolean unlimitedRanked;
    @io.swagger.v3.oas.annotations.media.Schema(nullable=true) private Integer historyMatchLimit;
    private boolean canViewCorrectAnswers;
    private boolean canViewExplanations;
    private boolean canViewAdvancedAnalytics;
    private boolean canFilterMistakes;
    private boolean canPracticeSimilar;
}
