package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.*;

@Getter @Setter
public class BattleHistoryItem {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private UUID battleId;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private String disciplineCode;
    @io.swagger.v3.oas.annotations.media.Schema(requiredMode = io.swagger.v3.oas.annotations.media.Schema.RequiredMode.REQUIRED)
    private BattleFormat format = BattleFormat.STANDARD;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private BattleMode mode;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private Outcome outcome;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private CompletionReason reason;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private PublicPlayer opponent;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int myScore;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int opponentScore;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int ratingDelta;
    @io.swagger.v3.oas.annotations.media.Schema(requiredMode = io.swagger.v3.oas.annotations.media.Schema.RequiredMode.REQUIRED, nullable = true)
    private String seasonId;
    @io.swagger.v3.oas.annotations.media.Schema(requiredMode = io.swagger.v3.oas.annotations.media.Schema.RequiredMode.REQUIRED)
    private boolean overtimePlayed;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private Instant createdAt;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private Instant finishedAt;
}
