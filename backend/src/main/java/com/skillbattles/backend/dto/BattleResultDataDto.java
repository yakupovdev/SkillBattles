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
    private String rulesVersion;
    @io.swagger.v3.oas.annotations.media.Schema(nullable = true)
    private String seasonId;
    private boolean overtimePlayed;
    private UUID winnerUserId;
    private Instant finishedAt;
    private List<BattleResultPlayerDto> players = new ArrayList<>();
}

