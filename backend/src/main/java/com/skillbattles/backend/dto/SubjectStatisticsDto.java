package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.Subject;
import lombok.*;

@Getter
@AllArgsConstructor
public class SubjectStatisticsDto {
    private final Subject subject;
    private final int rating;
    private final String rank;
    private final MatchCountsDto ranked;
    private final MatchCountsDto privateMatches;
}
