package com.skillbattles.backend.dto;
import lombok.*;
import java.time.Instant;
import java.util.UUID;
import io.swagger.v3.oas.annotations.media.Schema;
@Value
@Schema(additionalProperties = Schema.AdditionalPropertiesValue.FALSE)
public class StickerSendResponse {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED) UUID battleId;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED) UUID submissionId;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED) UUID senderUserId;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, allowableValues = {"gg", "fire", "facepalm", "lol", "hmm", "too_slow", "ez", "wait_what", "crying"}) String stickerId;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED) Instant sentAt;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED) Instant nextAllowedAt;
}
