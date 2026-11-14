package com.skillbattles.backend.dto;
import lombok.*;
@Getter @Setter
public class DisciplineStatisticsDto {
    private String disciplineCode;
    private int rating;
    private RankProgressDto rank;
    private CalibrationDto calibration;
    private int allTimePeakRating;
    private String allTimePeakRankCode;
    private String seasonId;
    private int seasonPeakRating;
    private String seasonPeakRankCode;
    private boolean seasonRolloverPending;
    private MatchCountsDto ranked;
    private MatchCountsDto privateMatches;
    private java.util.List<TopicStatsDto> topicStats;
    private java.util.List<RatingHistoryPointDto> ratingHistory;
}
