package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;
import java.time.Instant;
import java.util.*;

@Getter
@Setter
@io.swagger.v3.oas.annotations.media.Schema(requiredProperties={"id","isPro","nickname","score","correctCount","ratingBefore","ratingAfter","ratingDelta","kFactor","calibrationMatchesRemaining","rankBefore","rankAfter"})
public class BattleResultPlayerResponse {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private UUID id;
    @com.fasterxml.jackson.annotation.JsonProperty("isPro")
    private boolean pro;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private String nickname;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int score;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int correctCount;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int ratingBefore;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int ratingAfter;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int ratingDelta;
    @io.swagger.v3.oas.annotations.media.Schema(requiredMode = io.swagger.v3.oas.annotations.media.Schema.RequiredMode.REQUIRED)
    @com.fasterxml.jackson.annotation.JsonProperty("kFactor")
    @Getter(onMethod_ = @com.fasterxml.jackson.annotation.JsonProperty("kFactor"))
    @Setter(onMethod_ = @com.fasterxml.jackson.annotation.JsonProperty("kFactor"))
    private int kFactor;
    @io.swagger.v3.oas.annotations.media.Schema(requiredMode = io.swagger.v3.oas.annotations.media.Schema.RequiredMode.REQUIRED)
    private int calibrationMatchesRemaining;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private String rankBefore;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private String rankAfter;
}

