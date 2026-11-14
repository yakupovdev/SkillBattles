package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateBattleDto {
    private UUID firstUserId;
    private UUID secondUserId;
    private Subject subject;
    private BattleMode mode;
}

