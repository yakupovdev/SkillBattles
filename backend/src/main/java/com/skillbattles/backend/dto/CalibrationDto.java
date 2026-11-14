package com.skillbattles.backend.dto;
import lombok.*;
@Data @NoArgsConstructor @AllArgsConstructor
public class CalibrationDto {
    private int completedMatches;
    private int matchesRemaining;
    @com.fasterxml.jackson.annotation.JsonProperty("isCalibrating")
    private boolean calibrating;
    private int nextKFactor;
}
