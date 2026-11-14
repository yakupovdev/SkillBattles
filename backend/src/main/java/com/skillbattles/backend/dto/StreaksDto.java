package com.skillbattles.backend.dto;
import lombok.*;
import java.time.*;
import java.util.*;
@Data @NoArgsConstructor @AllArgsConstructor
public class StreaksDto {
    private String timezone;
    private int dailyCurrent;
    private int dailyBest;
    @io.swagger.v3.oas.annotations.media.Schema(nullable=true) private LocalDate lastQualifiedDate;
    private int weeklyCurrent;
    private int weeklyBest;
    private LocalDate currentWeekStart;
    private int currentWeekActiveDays;
    private int currentWeekTarget;
}
