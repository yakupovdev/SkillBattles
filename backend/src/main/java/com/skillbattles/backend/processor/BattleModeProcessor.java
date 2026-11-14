package com.skillbattles.backend.processor;

import com.skillbattles.backend.dto.BattleModeDto;
import java.util.List;

public interface BattleModeProcessor {
    List<BattleModeDto> getModes(java.util.UUID userId);
    void initializeActiveRatings();
}
