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
    public FrozenQuestionDto(UUID id, String code, String name, String prompt, List<FrozenOptionDto> options, UUID correct, String explanation) {
        this(id, code, "TEST_FOUNDATIONS", Difficulty.MEDIUM, name, prompt, options, correct, explanation);
    }
}
