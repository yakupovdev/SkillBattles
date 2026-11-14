package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BattleDto {
    private UUID id;
    private String disciplineCode;
    @io.swagger.v3.oas.annotations.media.Schema(requiredMode = io.swagger.v3.oas.annotations.media.Schema.RequiredMode.REQUIRED)
    private BattleFormat format = BattleFormat.STANDARD;
    private BattleMode mode;
    private BattlePhase phase;
    private int version;
    private Instant readyDeadline;
    private Instant countdownEndsAt;
    private Instant nextRoundStartsAt;
    private Instant nextTransitionAt;
    private Instant settledAt;
    private BattleStateDto state;
    private BattleResultDataDto result;
}
