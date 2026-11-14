package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.*;
import java.util.List;

@Getter
@Setter
@EqualsAndHashCode
public class QuestionImportDto {
    @NotBlank @Size(max = 200)
    private String externalKey;
    @NotNull @Positive
    private Integer contentVersion;
    @NotNull
    private Subject subject;
    @NotBlank @Size(max = 200)
    private String topic;
    @NotNull
    private Difficulty difficulty;
    @NotBlank
    private String prompt;
    @NotNull @Size(min = 4, max = 4)
    private List<@NotNull @Valid QuestionOptionImportDto> options;
    @NotNull @Pattern(regexp = "[ABCD]")
    private String correctOptionKey;
    @NotBlank
    private String explanation;
}
