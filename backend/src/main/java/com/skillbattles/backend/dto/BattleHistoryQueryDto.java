package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.Value;
import java.util.UUID;

@Value
public class BattleHistoryQueryDto {
    UUID userId;
    int page;
    int size;
    String sort;
    String disciplineCode;
    BattleMode mode;
}
