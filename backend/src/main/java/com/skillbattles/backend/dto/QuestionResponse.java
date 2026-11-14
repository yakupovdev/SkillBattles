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
    private String topic;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private String prompt;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private List<QuestionOptionResponse> options;
}

