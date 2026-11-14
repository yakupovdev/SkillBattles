package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BattleStateDto {
    private List<BattlePlayerDto> players = new ArrayList<>();
    private List<BattleRoundDto> rounds = new ArrayList<>();
    private int currentRoundIndex = -1;
    private int limitSeconds;
    private int countdownSeconds;
    private int revealSeconds;
    private int reconnectGraceSeconds;
}

