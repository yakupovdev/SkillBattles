package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;
import java.time.Instant;
import java.util.*;

@Getter
@Setter
@io.swagger.v3.oas.annotations.media.Schema(requiredProperties={"id","isPro","nickname","rating","rankCode","ready","connected","reconnectDeadline","score","correctCount","streak","answeredCurrentRound"})
public class BattlePlayerResponse {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private UUID id;
    @com.fasterxml.jackson.annotation.JsonProperty("isPro")
    private boolean pro;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private String nickname;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int rating;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private String rankCode;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private boolean ready;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private boolean connected;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private Instant reconnectDeadline;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int score;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int correctCount;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int streak;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private boolean answeredCurrentRound;
}

