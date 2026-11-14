package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.PresenceDto;
import java.util.*;

/** Trusted transport boundary: return only an authenticated, subscribed, unexpired connection. */
public interface PresenceService {
    Optional<PresenceDto> current(UUID userId);
}
