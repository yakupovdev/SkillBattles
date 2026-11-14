package com.skillbattles.backend.dto;

import java.time.Instant;
import java.util.UUID;

/** Post-commit metadata only. A transport must build a separate redacted snapshot for each recipient. */
public record BattleChangedEvent(UUID battleId, int version, Instant occurredAt) { }
