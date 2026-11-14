package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BattleRoundDto {
    private UUID id;
    private int number;
    @com.fasterxml.jackson.annotation.JsonProperty("isOvertimeRound")
    private boolean overtimeRound;
    private int limitSeconds;
    private int basePoints;
    private FrozenQuestionDto question;
    private Instant startedAt;
    private Instant deadline;
    private Instant revealEndsAt;
    private boolean completed;
    private List<BattleAnswerDto> answers = new ArrayList<>();
}
