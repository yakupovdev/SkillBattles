package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.UUID;

@Getter @Setter
public class DuelResponse {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private UUID id;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private String code;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private Subject subject;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private DuelStatus status;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private PublicPlayer host;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private PublicPlayer guest;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private Instant expiresAt;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private UUID battleId;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int version;
}
