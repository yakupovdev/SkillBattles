package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;
import java.time.Instant;
import java.util.*;

@Getter @Setter
public class DuelInvitationResponse {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private UUID id;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private UUID duelId;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private PublicPlayer host;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private PublicPlayer recipient;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private String disciplineCode;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private BattleFormat format;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private DuelInvitationStatus status;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private DuelInvitationReason reason;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private Instant createdAt;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private Instant expiresAt;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private UUID battleId;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, minimum = "1")
    private int version;
}
