package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AnswerViewDto {
    private UUID userId;
    private UUID selectedOptionId;
    private boolean correct;
    private Long elapsedMs;
    private int basePoints;
    private int speedBonus;
    private int streakBonus;
    private int tieBreakPoints;
    private int points;
    private boolean timedOut;
}
