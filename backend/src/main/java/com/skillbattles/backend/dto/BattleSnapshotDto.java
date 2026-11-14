package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BattleSnapshotDto {
    private UUID id;
    private String rulesVersion;
    @io.swagger.v3.oas.annotations.media.Schema(nullable = true)
    private String seasonId;
    private boolean overtimePlayed;
    private String disciplineCode;
    @io.swagger.v3.oas.annotations.media.Schema(requiredMode = io.swagger.v3.oas.annotations.media.Schema.RequiredMode.REQUIRED)
    private BattleFormat format = BattleFormat.STANDARD;
    private BattleMode mode;
    private BattlePhase phase;
    private int version;
    private Instant serverTime;
    private int questionCount;
    private Instant readyDeadline;
    private Instant countdownEndsAt;
    private Instant nextRoundStartsAt;
    private List<PlayerViewDto> players;
    private RoundViewDto round;
    private BattleResultDto result;
    private EntitlementsDto entitlements;
}

