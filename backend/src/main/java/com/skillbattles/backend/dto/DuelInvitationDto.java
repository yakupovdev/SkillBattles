package com.skillbattles.backend.dto;
import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.UUID;
@Value @Builder(toBuilder=true)
public class DuelInvitationDto {
    UUID id;
    UUID duelId;
    UUID hostId;
    UUID recipientId;
    String disciplineCode;
    BattleFormat format;
    DuelInvitationStatus status;
    DuelInvitationReason reason;
    Instant createdAt;
    Instant expiresAt;
    Instant resolvedAt;
    UUID battleId;
    int version;
}
