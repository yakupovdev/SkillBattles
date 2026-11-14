package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BattleSnapshotDto {
    private UUID id;
    private Subject subject;
    private BattleMode mode;
    private BattlePhase phase;
    private int version;
    private Instant serverTime;
    private int questionCount;
    private Instant readyDeadline;
    private Instant countdownEndsAt;
    private Instant nextRoundStartsAt;
    private List<PlayerViewDto> players;
    private RoundViewDto round;
    private BattleResultDto result;
}

