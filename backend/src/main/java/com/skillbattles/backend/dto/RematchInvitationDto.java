package com.skillbattles.backend.dto;

import lombok.Value;
import java.time.Instant;
import java.util.UUID;

@Value
public class RematchInvitationDto {
    UUID sourceBattleId;
    PublicPlayerDto requester;
    String disciplineCode;
    Instant expiresAt;
    int version;
}
