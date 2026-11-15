package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.*;
import java.util.UUID;
public interface BattleStickerProcessor {
    BattleStickerReceiptDto send(UUID battleId, UUID sender, BattleStickerCommandDto command);
    void cleanExpired();
}
