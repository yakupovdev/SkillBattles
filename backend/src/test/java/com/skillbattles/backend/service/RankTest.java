package com.skillbattles.backend.service;

import com.skillbattles.backend.RankFixtures;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.*;
import java.util.stream.Stream;
import static org.assertj.core.api.Assertions.*;

class RankTest {
    static Stream<Arguments> boundaries() {
        return RankFixtures.tiers().stream().flatMap(t -> Stream.of(Arguments.of(t.getFloorRating(), t.getCode()),
                Arguments.of(t.getCeilingExclusive() == null ? 100000 : t.getCeilingExclusive() - 1, t.getCode())));
    }
    @ParameterizedTest @MethodSource("boundaries")
    void derivesRankAtEveryBoundary(int rating, String expected) {
        assertThat(RankCalculator.fromRating(RankFixtures.tiers(), rating).getCode()).isEqualTo(expected);
    }
    @Test void initialRatingAndNegativeInput() {
        assertThat(RankCalculator.fromRating(RankFixtures.tiers(), 1000).getCode()).isEqualTo("SILVER_I");
        assertThatThrownBy(() -> RankCalculator.fromRating(RankFixtures.tiers(), -1)).isInstanceOf(IllegalArgumentException.class);
    }
}
