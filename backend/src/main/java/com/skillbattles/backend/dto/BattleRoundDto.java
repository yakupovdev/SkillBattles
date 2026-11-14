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
    private FrozenQuestionDto question;
    private Instant startedAt;
    private Instant deadline;
    private Instant revealEndsAt;
    private boolean completed;
    private List<BattleAnswerDto> answers = new ArrayList<>();
}

