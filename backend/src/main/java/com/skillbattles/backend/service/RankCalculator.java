package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.RankTierDto;
import java.util.List;

/** Pure calculation over a current or frozen catalogue; no hardcoded rating thresholds. */
public final class RankCalculator {
    private RankCalculator() { }
    public static RankTierDto fromRating(List<RankTierDto> tiers, int rating) {
        if (rating < 0) throw new IllegalArgumentException("Rating cannot be negative.");
        return tiers.stream().filter(tier -> rating >= tier.getFloorRating() && (tier.getCeilingExclusive() == null || rating < tier.getCeilingExclusive()))
                .findFirst().orElseThrow(() -> new IllegalStateException("Rank catalogue does not cover rating."));
    }
}
