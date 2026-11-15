package com.skillbattles.backend.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;
import lombok.*;
import java.util.UUID;

@Data @NoArgsConstructor
@Schema(additionalProperties = Schema.AdditionalPropertiesValue.FALSE)
public class SendBattleStickerRequest {
    @NotBlank @Size(max = 64)
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, allowableValues = {"gg", "fire", "facepalm", "lol", "hmm", "too_slow", "ez", "wait_what", "crying"})
    @Setter(AccessLevel.NONE)
    private String stickerId;
    @com.fasterxml.jackson.annotation.JsonSetter("stickerId")
    public void readStickerId(com.fasterxml.jackson.databind.JsonNode value) {
        if (value == null || value.isNull()) { stickerId = null; return; }
        if (!value.isTextual()) throw new IllegalArgumentException("Sticker ID must be a string.");
        stickerId = value.textValue();
    }
    @NotNull @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private UUID submissionId;
}
