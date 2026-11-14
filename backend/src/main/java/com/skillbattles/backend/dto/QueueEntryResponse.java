package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.UUID;

@Getter @Setter
public class QueueEntryResponse {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private UUID id;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private String disciplineCode;
    @io.swagger.v3.oas.annotations.media.Schema(requiredMode = io.swagger.v3.oas.annotations.media.Schema.RequiredMode.REQUIRED)
    private BattleFormat format = BattleFormat.STANDARD;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private QueueStatus status;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private Instant createdAt;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private Instant expiresAt;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int ratingWindow;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private UUID battleId;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int version;
    @Schema(requiredMode=Schema.RequiredMode.REQUIRED,nullable=true) private ErrorResponse error;
}
