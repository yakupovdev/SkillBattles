package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.*;

@Getter @Setter
public class ReviewRoundResponse {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private UUID roundId;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int number;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private boolean completed;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private ReviewQuestionResponse question;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private List<RoundAnswerResponse> answers;
}
