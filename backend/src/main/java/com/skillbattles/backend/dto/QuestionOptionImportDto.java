package com.skillbattles.backend.dto;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter
@Setter
@EqualsAndHashCode
public class QuestionOptionImportDto {
    @NotNull
    @Pattern(regexp = "[ABCD]")
    private String key;
    @NotBlank
    private String text;
}
