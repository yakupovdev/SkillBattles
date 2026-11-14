package com.skillbattles.backend.dto;
import lombok.*;
import java.time.*;
import java.util.*;
@Data @NoArgsConstructor @AllArgsConstructor
@io.swagger.v3.oas.annotations.media.Schema(requiredProperties={"planCode","timezone","date","freeRankedLimit","rankedStartedToday","freeRankedRemaining","resetsAt","canStartRanked","entitlements"})
public class LimitsResponse {
    private String planCode;
    private String timezone;
    private LocalDate date;
    private int freeRankedLimit;
    private int rankedStartedToday;
    @io.swagger.v3.oas.annotations.media.Schema(nullable=true) private Integer freeRankedRemaining;
    private Instant resetsAt;
    private boolean canStartRanked;
    private Entitlements entitlements;
}
