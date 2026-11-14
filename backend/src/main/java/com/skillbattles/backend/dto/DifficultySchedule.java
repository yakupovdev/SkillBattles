package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import io.swagger.v3.oas.annotations.media.Schema;
import java.util.*;

@Getter @Setter
public class DifficultySchedule {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int minRating;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private Integer maxRatingExclusive;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private List<Difficulty> roundDifficulties;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private boolean contentAvailable;
}
