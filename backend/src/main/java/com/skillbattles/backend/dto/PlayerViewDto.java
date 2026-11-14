package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PlayerViewDto {
    private UUID id;
    private String nickname;
    private int rating;
    private String rank;
    private boolean ready;
    private boolean connected;
    private Instant reconnectDeadline;
    private int score;
    private int correctCount;
    private int streak;
    private boolean answeredCurrentRound;
}

