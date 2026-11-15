package com.skillbattles.backend.service;
import com.skillbattles.backend.dto.*;
import java.util.*;
public interface BattleStickerStateService {
    void beginBattleRead(UUID battleId);
    void endBattleRead(UUID battleId);
    BattleStickerAcceptanceDto accept(BattleDto battle, UUID sender, BattleStickerCommandDto command);
    void cleanExpired();
    List<BattleStickerSequenceDto> sequenceCleanupCandidates();
    void forgetTerminalSequence(UUID battleId);
}
