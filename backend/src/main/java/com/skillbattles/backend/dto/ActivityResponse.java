package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.UUID;

@Getter @Setter
public class ActivityResponse {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private ActivityType type;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private UUID resourceId;
    @Schema(requiredMode=Schema.RequiredMode.REQUIRED,nullable=true,allowableValues={"DUEL","REMATCH"}) private String resourceKind;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private UUID battleId;
}
