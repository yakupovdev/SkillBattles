package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;
import java.time.Instant;
import java.util.*;

@Getter
@Setter
public class BattleRoundResponse {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private UUID id;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int number;
    @com.fasterxml.jackson.annotation.JsonProperty("isOvertimeRound")
    @io.swagger.v3.oas.annotations.media.Schema(requiredMode = io.swagger.v3.oas.annotations.media.Schema.RequiredMode.REQUIRED)
    private boolean overtimeRound;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private Instant startedAt;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private Instant deadline;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int limitSeconds;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private QuestionResponse question;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private UUID mySelectedOptionId;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private RoundRevealResponse reveal;
}
