package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;
import java.time.Instant;
import java.util.*;

@Getter
@Setter
@io.swagger.v3.oas.annotations.media.Schema(requiredProperties={"id","rulesVersion","seasonId","overtimePlayed","disciplineCode","format","mode","phase","version","serverTime","questionCount","readyDeadline","countdownEndsAt","nextRoundStartsAt","players","round","result","entitlements"})
public class BattleSnapshot {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private UUID id;
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
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private BattlePhase phase;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int version;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private Instant serverTime;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int questionCount;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private Instant readyDeadline;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private Instant countdownEndsAt;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private Instant nextRoundStartsAt;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private List<BattlePlayerResponse> players;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private BattleRoundResponse round;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private BattleResultResponse result;
    private Entitlements entitlements;
}
