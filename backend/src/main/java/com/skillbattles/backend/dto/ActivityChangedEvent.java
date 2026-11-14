package com.skillbattles.backend.dto;

import java.time.Instant;

/** Immutable committed resource snapshots, not references to mutable registry state. */
public record ActivityChangedEvent(QueueEntryDto entry, DuelDto duel, Instant occurredAt) { }
