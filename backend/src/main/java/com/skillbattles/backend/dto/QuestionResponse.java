package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;
import java.time.Instant;
import java.util.*;

@Getter
@Setter
public class QuestionResponse {
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
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true,
            pattern = "^/media/questions/[A-Z][A-Z0-9_]{1,63}/[a-f0-9]{8}/[a-f0-9]{64}\\.png$",
            description = "Immutable origin-relative illustration URL from the frozen question; null when absent.")
    private String imageUrl;
}
