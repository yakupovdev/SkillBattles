package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;
import java.time.Instant;
import java.util.*;

@Getter
@Setter
public class BattleResultPlayerResponse {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private UUID id;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private String nickname;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int score;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int correctCount;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int ratingBefore;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int ratingAfter;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int ratingDelta;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private String rankBefore;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private String rankAfter;
}

