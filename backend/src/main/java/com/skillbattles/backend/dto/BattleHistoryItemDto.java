package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Getter @Setter
public class BattleHistoryItemDto {
    private UUID battleId;
    private Subject subject;
    private BattleMode mode;
    private Outcome outcome;
    private CompletionReason reason;
    private PublicPlayerDto opponent;
    private int myScore;
    private int opponentScore;
    private int ratingDelta;
    private Instant createdAt;
    private Instant finishedAt;
}
