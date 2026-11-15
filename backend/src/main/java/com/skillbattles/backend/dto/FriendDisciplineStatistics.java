package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;
import java.time.Instant;
import java.util.*;

@Getter @Setter
public class FriendDisciplineStatistics {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private String disciplineCode;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int rating;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private RankProgress rank;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private Calibration calibration;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int allTimePeakRating;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private String allTimePeakRankCode;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private String seasonId;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int seasonPeakRating;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private String seasonPeakRankCode;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private boolean seasonRolloverPending;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private MatchCountsResponse ranked;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private MatchCountsResponse privateMatches;
}
