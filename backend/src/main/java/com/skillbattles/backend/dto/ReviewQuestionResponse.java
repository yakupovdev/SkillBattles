package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.*;

@Getter @Setter
public class ReviewQuestionResponse {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private UUID id;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private String topicCode;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private Difficulty difficulty;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private String topicName;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private String prompt;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private List<QuestionOptionResponse> options;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private UUID correctOptionId;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private String explanation;
}
