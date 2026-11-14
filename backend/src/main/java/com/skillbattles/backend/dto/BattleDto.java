package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BattleDto {
    private UUID id;
    private Subject subject;
    private BattleMode mode;
    private BattlePhase phase;
    private int version;
    private Instant readyDeadline;
    private Instant countdownEndsAt;
    private Instant nextRoundStartsAt;
    private Instant nextTransitionAt;
    private Instant settledAt;
    private BattleStateDto state;
    private BattleResultDataDto result;
}

