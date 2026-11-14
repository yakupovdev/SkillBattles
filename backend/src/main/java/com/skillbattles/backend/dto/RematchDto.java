package com.skillbattles.backend.dto;
import lombok.*;import java.util.*;import java.time.Instant;
@Value @Builder(toBuilder=true) public class RematchDto {
 UUID sourceBattleId;String status;List<UUID> requestedBy;Instant expiresAt;UUID battleId;int version;List<UUID> participants;
}
