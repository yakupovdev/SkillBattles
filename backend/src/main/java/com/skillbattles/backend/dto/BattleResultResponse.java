package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;
import java.time.Instant;
import java.util.*;

@Getter
@Setter
public class BattleResultResponse {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private UUID battleId;
    @io.swagger.v3.oas.annotations.media.Schema(requiredMode = io.swagger.v3.oas.annotations.media.Schema.RequiredMode.REQUIRED)
    private String rulesVersion;
    @io.swagger.v3.oas.annotations.media.Schema(requiredMode = io.swagger.v3.oas.annotations.media.Schema.RequiredMode.REQUIRED, nullable = true)
    private String seasonId;
    @io.swagger.v3.oas.annotations.media.Schema(requiredMode = io.swagger.v3.oas.annotations.media.Schema.RequiredMode.REQUIRED)
    private boolean overtimePlayed;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private String disciplineCode;
    @io.swagger.v3.oas.annotations.media.Schema(requiredMode = io.swagger.v3.oas.annotations.media.Schema.RequiredMode.REQUIRED)
    private BattleFormat format = BattleFormat.STANDARD;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private BattleMode mode;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, allowableValues = {"FINISHED", "CANCELLED"})
    private BattlePhase status;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private CompletionReason reason;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private UUID winnerUserId;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private Outcome myOutcome;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private Instant finishedAt;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private List<BattleResultPlayerResponse> players;
}

