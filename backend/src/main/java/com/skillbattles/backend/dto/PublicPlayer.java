package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.UUID;

@Getter @Setter
@io.swagger.v3.oas.annotations.media.Schema(requiredProperties={"id","isPro","nickname"})
public class PublicPlayer {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private UUID id;
    @com.fasterxml.jackson.annotation.JsonProperty("isPro")
    private boolean pro;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private String nickname;
}
