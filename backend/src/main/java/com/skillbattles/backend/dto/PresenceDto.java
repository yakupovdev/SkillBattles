package com.skillbattles.backend.dto;

import lombok.*;
import java.time.Instant;
import java.util.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PresenceDto {
    private UUID sessionId;
    private Instant expiresAt;
    private Instant observedAt;
    private Instant previousDisconnectAt;

    public PresenceDto(UUID sessionId, Instant expiresAt) { this(sessionId, expiresAt, null); }
    public PresenceDto(UUID sessionId, Instant expiresAt, Instant observedAt) { this(sessionId, expiresAt, observedAt, null); }
}

