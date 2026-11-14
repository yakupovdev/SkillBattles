package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.PresenceDto;
import java.util.*;
import java.time.Instant;

/** Trusted transport boundary: return only an authenticated, subscribed, unexpired connection. */
public interface PresenceService {
    Optional<PresenceDto> current(UUID userId);
    default Optional<PresenceDto> observed(UUID userId) {
        return current(userId).or(() -> lastDisconnectedAt(userId).map(at -> new PresenceDto(null, null, at)));
    }
    default Optional<Instant> lastDisconnectedAt(UUID userId) { return Optional.empty(); }
}
