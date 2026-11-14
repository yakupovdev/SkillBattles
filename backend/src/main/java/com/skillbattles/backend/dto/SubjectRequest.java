package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.Subject;
import jakarta.validation.constraints.NotNull;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.*;

@Getter @Setter
public class SubjectRequest {
    @NotNull @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private Subject subject;
}
