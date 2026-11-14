package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;
import java.time.Instant;
import java.util.*;

@Getter
@Setter
public class RoundAnswerResponse {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private UUID userId;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private UUID selectedOptionId;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private boolean correct;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private Long elapsedMs;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int basePoints;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int speedBonus;
    @io.swagger.v3.oas.annotations.media.Schema(requiredMode = io.swagger.v3.oas.annotations.media.Schema.RequiredMode.REQUIRED)
    private int streakBonus;
    @io.swagger.v3.oas.annotations.media.Schema(requiredMode = io.swagger.v3.oas.annotations.media.Schema.RequiredMode.REQUIRED)
    private int tieBreakPoints;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int points;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private boolean timedOut;
}
