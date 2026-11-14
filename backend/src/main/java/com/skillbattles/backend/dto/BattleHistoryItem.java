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
    private Subject subject;
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
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private Instant createdAt;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private Instant finishedAt;
}
