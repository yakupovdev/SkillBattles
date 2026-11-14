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
    private Subject subject;
    private String topic;
    private String prompt;
    private List<FrozenOptionDto> options;
    private UUID correctOptionId;
    private String explanation;
}

