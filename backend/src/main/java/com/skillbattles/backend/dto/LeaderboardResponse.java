package com.skillbattles.backend.dto;
import lombok.Value;import java.time.Instant;import java.util.List;
@Value public class LeaderboardResponse {String disciplineCode;SeasonResponse season;Instant generatedAt;List<LeaderboardEntry> top;@io.swagger.v3.oas.annotations.media.Schema(nullable=true) LeaderboardEntry me;}
