package com.skillbattles.backend.dto;
import lombok.*;
import java.time.Instant;
import java.util.UUID;
import io.swagger.v3.oas.annotations.media.Schema;
@Value
@Schema(additionalProperties = Schema.AdditionalPropertiesValue.FALSE)
public class BattleStickerData {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED) UUID battleId;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED) UUID submissionId;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED) UUID senderUserId;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, maxLength = 64, description = "Open wire string; older clients ignore unknown future IDs.") String stickerId;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED) Instant sentAt;
}
