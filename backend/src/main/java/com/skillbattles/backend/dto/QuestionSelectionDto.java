package com.skillbattles.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import java.util.List;

@Getter
@AllArgsConstructor
public class QuestionSelectionDto {
    private final String disciplineCode;
    private final int count;
    private final List<QuestionSeenDto> recentlySeen;
    private final com.skillbattles.backend.entity.Difficulty difficulty;
    public QuestionSelectionDto(String code, int count, List<QuestionSeenDto> seen) {
        this(code, count, seen, com.skillbattles.backend.entity.Difficulty.MEDIUM);
    }
}
