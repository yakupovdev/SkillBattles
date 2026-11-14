package com.skillbattles.backend.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class RatingDto {
    private String disciplineCode;
    private int rating;
    private java.util.UUID userId;
    private int calibrationCompletedMatches;
    private String seasonId;
    private int seasonPeakRating;
    private int allTimePeakRating;
    private boolean seasonRolloverPending;
    private String rankCode;
    private String rankName;
}
