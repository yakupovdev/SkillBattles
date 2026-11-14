package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.UUID;

@Value @Builder(toBuilder = true)
public class QueueEntryDto {
    UUID id;
    UUID userId;
    int rating;
    Subject subject;
    QueueStatus status;
    Instant createdAt;
    Instant expiresAt;
    int ratingWindow;
    UUID battleId;
    int version;
}
