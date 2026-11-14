package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;
import java.time.Instant;
import java.util.*;

@Getter
@Setter
public class AnswerReceipt {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private UUID battleId;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private UUID roundId;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private UUID submissionId;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, allowableValues = "true")
    private boolean accepted;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private Instant acceptedAt;
}

