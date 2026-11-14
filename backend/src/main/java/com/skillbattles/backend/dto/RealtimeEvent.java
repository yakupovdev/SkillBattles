package com.skillbattles.backend.dto;

import java.time.Instant;
import java.util.UUID;

public record RealtimeEvent(UUID eventId, String type, UUID resourceId, int version, Instant occurredAt, BattleSnapshot data) { }
