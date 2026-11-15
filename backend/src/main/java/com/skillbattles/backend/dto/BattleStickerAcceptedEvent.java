package com.skillbattles.backend.dto;
import java.util.UUID;
public record BattleStickerAcceptedEvent(UUID opponentUserId, RealtimeEvent<BattleStickerData> envelope) { }
