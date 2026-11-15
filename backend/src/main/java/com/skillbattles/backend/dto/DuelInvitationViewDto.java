package com.skillbattles.backend.dto;
import com.skillbattles.backend.entity.*;
import java.time.Instant;
import java.util.*;
public record DuelInvitationViewDto(UUID id, UUID duelId, PublicPlayerDto host, PublicPlayerDto recipient, String disciplineCode, BattleFormat format, DuelInvitationStatus status, DuelInvitationReason reason, Instant createdAt, Instant expiresAt, UUID battleId, int version) {  }
