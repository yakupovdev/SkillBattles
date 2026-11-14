package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.*;

@Getter @Setter
@io.swagger.v3.oas.annotations.media.Schema(requiredProperties={"battleId","rulesVersion","disciplineCode","mode","rounds","answerAccess","mistakesOnly"})
public class BattleReview {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private UUID battleId;
    @io.swagger.v3.oas.annotations.media.Schema(requiredMode = io.swagger.v3.oas.annotations.media.Schema.RequiredMode.REQUIRED)
    private String rulesVersion;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private String disciplineCode;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private BattleMode mode;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private List<ReviewRoundResponse> rounds;
    private AnswerAccess answerAccess;
    private boolean mistakesOnly;
}
