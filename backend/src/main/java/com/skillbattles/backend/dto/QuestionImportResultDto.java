package com.skillbattles.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class QuestionImportResultDto {
    private final boolean dryRun;
    private final int validated;
    private final int inserted;
    private final int unchanged;
}
