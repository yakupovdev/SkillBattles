package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.UUID;

@Value @Builder(toBuilder = true)
public class ActivityDto {
    ActivityType type;
    UUID resourceId;
    UUID battleId;
}
