package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BattleResultDto {
    private UUID battleId;
    private String rulesVersion;
    @io.swagger.v3.oas.annotations.media.Schema(nullable = true)
    private String seasonId;
    private boolean overtimePlayed;
    private String disciplineCode;
    @io.swagger.v3.oas.annotations.media.Schema(requiredMode = io.swagger.v3.oas.annotations.media.Schema.RequiredMode.REQUIRED)
    private BattleFormat format = BattleFormat.STANDARD;
    private BattleMode mode;
    private BattlePhase status;
    private CompletionReason reason;
    private UUID winnerUserId;
    private Outcome myOutcome;
    private Instant finishedAt;
    private List<BattleResultPlayerDto> players;
}

