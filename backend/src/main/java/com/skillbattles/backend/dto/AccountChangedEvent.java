package com.skillbattles.backend.dto;
import java.util.UUID;
import java.time.Instant;
public record AccountChangedEvent(UUID userId,int version,Instant occurredAt) { }
