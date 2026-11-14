package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BattleResultPlayerDto {
    private UUID id;
    private String nickname;
    private int score;
    private int correctCount;
    private int ratingBefore;
    private int ratingAfter;
    private int ratingDelta;
    private String rankBefore;
    private String rankAfter;
}

