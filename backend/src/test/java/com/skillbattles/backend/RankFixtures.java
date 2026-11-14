package com.skillbattles.backend;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.skillbattles.backend.dto.RankTierDto;
import java.util.*;

public final class RankFixtures {
    private RankFixtures() { }
    public static List<RankTierDto> tiers() {
        try (var input = RankFixtures.class.getResourceAsStream("/fixtures/ranks-test-only.json")) {
            return new ObjectMapper().readValue(Objects.requireNonNull(input), new TypeReference<List<RankTierDto>>() { });
        } catch (java.io.IOException ex) { throw new IllegalStateException(ex); }
    }
}
