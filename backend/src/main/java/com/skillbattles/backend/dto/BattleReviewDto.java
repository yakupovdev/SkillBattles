package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Getter @Setter
public class BattleReviewDto {
    private UUID battleId;
    private String rulesVersion;
    private String disciplineCode;
    @io.swagger.v3.oas.annotations.media.Schema(requiredMode = io.swagger.v3.oas.annotations.media.Schema.RequiredMode.REQUIRED)
    private BattleFormat format = BattleFormat.STANDARD;
    private BattleMode mode;
    private List<ReviewRoundDto> rounds;
    private AnswerAccessDto answerAccess;
    private boolean mistakesOnly;
}
