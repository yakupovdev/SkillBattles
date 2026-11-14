package com.skillbattles.backend.dto;
import lombok.*;import java.util.UUID;
@Value public class ReportCommandDto {UUID userId;UUID battleId;UUID roundId;String reason;String comment;}
