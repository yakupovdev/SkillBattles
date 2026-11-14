package com.skillbattles.backend.service;

import com.skillbattles.backend.entity.Rank;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import static org.assertj.core.api.Assertions.*;

class RankTest {
    @ParameterizedTest
    @CsvSource({"0,Rookie", "1099,Rookie", "1100,Challenger", "1299,Challenger", "1300,Strategist",
            "1499,Strategist", "1500,Expert", "1799,Expert", "1800,Master", "3000,Master"})
    void derivesRankAtEveryBoundary(int rating, String expected) {
        assertThat(Rank.fromRating(rating).getDisplayName()).isEqualTo(expected);
    }
}
