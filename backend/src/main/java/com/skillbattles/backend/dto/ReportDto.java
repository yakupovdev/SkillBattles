package com.skillbattles.backend.dto;
import lombok.*;import java.util.UUID;import java.time.Instant;
@Getter @Setter public class ReportDto {private UUID id;private UUID battleId;private UUID roundId;private Instant createdAt;private boolean created;}
