package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.PresenceDto;
import java.util.*;

/** Closed until the realtime stage supplies an authenticated transport adapter. */
public class PresenceServiceImpl implements PresenceService {
    @Override public Optional<PresenceDto> current(UUID userId) { return Optional.empty(); }
}
