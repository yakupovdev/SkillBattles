package com.skillbattles.backend.dto;

import jakarta.validation.constraints.*;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import java.util.Locale;

@Getter
public class JoinDuelRequest {
    @NotNull @Pattern(regexp = "[A-Z0-9]{6}")
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, minLength = 6, maxLength = 6, pattern = "^[A-Za-z0-9]{6}$", description = "Trim whitespace and uppercase before validation.")
    private String code;
    public void setCode(String value) { code = value == null ? null : value.trim().toUpperCase(Locale.ROOT); }
}
