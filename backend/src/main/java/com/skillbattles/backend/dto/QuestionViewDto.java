package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class QuestionViewDto {
    private UUID id;
    private String topicCode;
    private Difficulty difficulty;
    private String topicName;
    private String prompt;
    private List<OptionViewDto> options;
}

