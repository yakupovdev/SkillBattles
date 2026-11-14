package com.skillbattles.backend.dto;
import lombok.*;import java.util.*;import java.time.Instant;
@Getter @Setter public class RematchResponse {
 private UUID sourceBattleId;@io.swagger.v3.oas.annotations.media.Schema(allowableValues={"WAITING","MATCHED","EXPIRED","CANCELLED"}) private String status;private List<UUID> requestedBy;private Instant expiresAt;@io.swagger.v3.oas.annotations.media.Schema(nullable=true) private UUID battleId;private int version;
}
