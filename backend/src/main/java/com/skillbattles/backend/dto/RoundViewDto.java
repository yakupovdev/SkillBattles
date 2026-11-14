package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RoundViewDto {
    private UUID id;
    private int number;
    @com.fasterxml.jackson.annotation.JsonProperty("isOvertimeRound")
    private boolean overtimeRound;
    private Instant startedAt;
    private Instant deadline;
    private int limitSeconds;
    private QuestionViewDto question;
    private UUID mySelectedOptionId;
    private RevealViewDto reveal;
}

