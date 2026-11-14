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
    private String disciplineCode;
    @io.swagger.v3.oas.annotations.media.Schema(requiredMode = io.swagger.v3.oas.annotations.media.Schema.RequiredMode.REQUIRED)
    private BattleFormat format = BattleFormat.STANDARD;
    private BattleMode mode;
    public CreateBattleDto(UUID first, UUID second, String code, BattleMode mode) { this(first, second, code, BattleFormat.STANDARD, mode); }
}

