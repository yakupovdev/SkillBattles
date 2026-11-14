package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.Subject;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class SubjectStatisticsResponse {
    private Subject subject;
    private int rating;
    @Schema(allowableValues = {"Rookie", "Challenger", "Strategist", "Expert", "Master"})
    private String rank;
    private MatchCountsResponse ranked;
    private MatchCountsResponse privateMatches;
}
