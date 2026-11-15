package com.skillbattles.backend.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;
import java.time.Instant;
import java.util.UUID;

@Getter @Setter
@Schema(requiredProperties = {"sourceBattleId", "requester", "disciplineCode", "expiresAt", "version"})
public class RematchInvitation {
    @Schema(description = "Completed source PRIVATE battle UUID; invitation identity")
    private UUID sourceBattleId;
    private PublicPlayer requester;
    @Schema(description = "Open catalogue code", example = "SAT_MATH")
    private String disciplineCode;
    @Schema(description = "Original first-consent deadline; never extended by recovery")
    private Instant expiresAt;
    @Schema(minimum = "1", description = "Version scoped to this source battle within the current backend process")
    private int version;
}
