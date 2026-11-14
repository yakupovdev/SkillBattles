package com.skillbattles.backend.dto;
import lombok.*;import java.util.UUID;import java.time.Instant;
@Getter @Setter public class ReportResponse {private UUID id;private UUID battleId;private UUID roundId;private Instant createdAt;@io.swagger.v3.oas.annotations.media.Schema(allowableValues={"RECEIVED"}) private String status;}
