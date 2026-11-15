package com.skillbattles.backend.dto;
import lombok.*;
import java.time.Instant;
import java.util.UUID;
@Value
public class BattleStickerReceiptDto { UUID battleId; UUID submissionId; UUID senderUserId; String stickerId; Instant sentAt; Instant nextAllowedAt; }
