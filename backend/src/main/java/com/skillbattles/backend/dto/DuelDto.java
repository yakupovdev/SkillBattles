package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.UUID;

@Value @Builder(toBuilder = true)
public class DuelDto {
    UUID id;
    String code;
    String disciplineCode;
    @lombok.Builder.Default
    BattleFormat format = BattleFormat.STANDARD;
    DuelStatus status;
    PublicPlayerDto host;
    PublicPlayerDto guest;
    Instant expiresAt;
    UUID battleId;
    int version;
}
