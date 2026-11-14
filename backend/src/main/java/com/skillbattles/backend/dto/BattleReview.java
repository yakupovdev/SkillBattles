package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.*;

@Getter @Setter
public class BattleReview {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private UUID battleId;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private Subject subject;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private BattleMode mode;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private List<ReviewRoundResponse> rounds;
}
