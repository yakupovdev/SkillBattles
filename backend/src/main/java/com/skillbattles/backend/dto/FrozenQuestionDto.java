package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class FrozenQuestionDto {
    private UUID id;
    private String disciplineCode;
    private String topicCode;
    private Difficulty difficulty;
    private String topicName;
    private String prompt;
    private List<FrozenOptionDto> options;
    private UUID correctOptionId;
    private String explanation;
    private String imageKey;
    public FrozenQuestionDto(UUID id, String disciplineCode, String topicCode, Difficulty difficulty, String topicName,
                             String prompt, List<FrozenOptionDto> options, UUID correctOptionId, String explanation) {
        this(id, disciplineCode, topicCode, difficulty, topicName, prompt, options, correctOptionId, explanation, null);
    }
    public FrozenQuestionDto(UUID id, String code, String name, String prompt, List<FrozenOptionDto> options, UUID correct, String explanation) {
        this(id, code, "TEST_FOUNDATIONS", Difficulty.MEDIUM, name, prompt, options, correct, explanation);
    }
}
