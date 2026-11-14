package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Getter @Setter
public class BattleHistoryItemDto {
    private UUID battleId;
    private String disciplineCode;
    @io.swagger.v3.oas.annotations.media.Schema(requiredMode = io.swagger.v3.oas.annotations.media.Schema.RequiredMode.REQUIRED)
    private BattleFormat format = BattleFormat.STANDARD;
    private BattleMode mode;
    private Outcome outcome;
    private CompletionReason reason;
    private PublicPlayerDto opponent;
    private int myScore;
    private int opponentScore;
    private int ratingDelta;
    @io.swagger.v3.oas.annotations.media.Schema(nullable = true)
    private String seasonId;
    private boolean overtimePlayed;
    private Instant createdAt;
    private Instant finishedAt;
}
