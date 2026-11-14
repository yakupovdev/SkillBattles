package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BattlePlayerDto {
    private UUID id;
    private String nickname;
    private int rating;
    private boolean ready;
    private boolean connected;
    private UUID sessionId;
    private Instant sessionExpiresAt;
    private Instant reconnectDeadline;
    private int score;
    private int correctCount;
    private int streak;
}

