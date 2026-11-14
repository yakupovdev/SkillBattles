package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.ActivityType;
import java.util.UUID;

public record ActivityReservationDto(ActivityType type, UUID resourceId) { }
