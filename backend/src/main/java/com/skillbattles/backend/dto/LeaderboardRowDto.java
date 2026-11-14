package com.skillbattles.backend.dto;
import java.util.UUID;import lombok.Value;
@Value public class LeaderboardRowDto {long position;UUID userId;String nickname;int rating;int calibrationCompletedMatches;}
