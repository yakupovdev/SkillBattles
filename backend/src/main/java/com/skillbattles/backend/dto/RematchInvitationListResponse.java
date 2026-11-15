package com.skillbattles.backend.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;
import java.time.Instant;
import java.util.List;

@Getter @Setter
@Schema(requiredProperties = {"data", "serverTime"})
public class RematchInvitationListResponse {
    @Schema(description = "Complete incoming WAITING set, ordered by expiresAt then sourceBattleId")
    private List<RematchInvitation> data;
    @Schema(description = "Server instant used to evaluate expiration for this snapshot")
    private Instant serverTime;
}
