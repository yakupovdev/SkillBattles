package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Getter @Setter
public class ReviewQuestionDto {
    private UUID id;
    private String topicCode;
    private Difficulty difficulty;
    private String topicName;
    private String prompt;
    private List<FrozenOptionDto> options;
    private UUID correctOptionId;
    private String explanation;
}
