package com.skillbattles.backend.entity;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum Rank {
    ROOKIE("Rookie"), CHALLENGER("Challenger"), STRATEGIST("Strategist"), EXPERT("Expert"), MASTER("Master");

    private final String displayName;

    public static Rank fromRating(int rating) {
        if (rating < 0) throw new IllegalArgumentException("Rating must not be negative.");
        if (rating >= 1800) return MASTER;
        if (rating >= 1500) return EXPERT;
        if (rating >= 1300) return STRATEGIST;
        if (rating >= 1100) return CHALLENGER;
        return ROOKIE;
    }
}
