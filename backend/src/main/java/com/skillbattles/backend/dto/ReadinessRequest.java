package com.skillbattles.backend.dto;

import jakarta.validation.constraints.*;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ReadinessRequest {
    @NotNull(message = "Ready is required.")
    @AssertTrue(message = "Ready must be true.")
    @Schema(allowableValues = "true", requiredMode = Schema.RequiredMode.REQUIRED)
    private Boolean ready;
}
