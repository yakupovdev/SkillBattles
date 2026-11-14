package com.skillbattles.backend.dto;

import jakarta.validation.constraints.*;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.*;

@Getter @Setter
public class DisciplineRequest {
    @NotBlank @Pattern(regexp = "[A-Z][A-Z0-9_]{1,63}") @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private String disciplineCode;
    @NotNull @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private com.skillbattles.backend.entity.BattleFormat format;
}
