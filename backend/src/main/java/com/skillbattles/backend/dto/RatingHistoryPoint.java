package com.skillbattles.backend.dto;
import lombok.*;import java.time.Instant;import java.util.UUID;
@Getter @Setter public class RatingHistoryPoint {private UUID battleId;private String seasonId;private Instant finishedAt;private int ratingBefore;private int ratingAfter;private int ratingDelta;}
