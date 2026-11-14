package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BattleCountsDto {
    private Subject subject;
    private BattleMode mode;
    private MatchCountsDto counts;
}

