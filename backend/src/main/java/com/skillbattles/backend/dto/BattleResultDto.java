package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BattleResultDto {
    private UUID battleId;
    private Subject subject;
    private BattleMode mode;
    private BattlePhase status;
    private CompletionReason reason;
    private UUID winnerUserId;
    private Outcome myOutcome;
    private Instant finishedAt;
    private List<BattleResultPlayerDto> players;
}

