package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BattleStateDto {
    private String rulesVersion = "0.3";
    private List<RankTierDto> rankTiers = new ArrayList<>();
    private FrozenQuestionDto overtimeQuestion;
    private int overtimeSeconds;
    private int mainQuestionCount = 5;
    private String seasonId;
    private List<BattlePlayerDto> players = new ArrayList<>();
    private List<BattleRoundDto> rounds = new ArrayList<>();
    private int currentRoundIndex = -1;
    private int limitSeconds;
    private int countdownSeconds;
    private int revealSeconds;
    private int reconnectGraceSeconds;
}

