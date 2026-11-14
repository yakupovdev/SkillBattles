package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BattleResultDataDto {
    private CompletionReason reason;
    private UUID winnerUserId;
    private Instant finishedAt;
    private List<BattleResultPlayerDto> players = new ArrayList<>();
}

