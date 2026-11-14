package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.Difficulty;
import java.util.*;

/** Pure availability over counts supplied by QuestionService, including one MEDIUM reserve. */
public final class DisciplineContentPolicy {
    private DisciplineContentPolicy() { }
    public static boolean available(DifficultyScheduleDto schedule, Map<Difficulty, Long> counts) {
        Map<Difficulty, Long> needed = new EnumMap<>(Difficulty.class);
        schedule.getRoundDifficulties().forEach(d -> needed.merge(d, 1L, Long::sum));
        needed.merge(Difficulty.MEDIUM, 1L, Long::sum);
        return needed.entrySet().stream().allMatch(e -> counts.getOrDefault(e.getKey(), 0L) >= e.getValue());
    }
    public static DifficultyScheduleDto schedule(DisciplineDto discipline, int rating) {
        return discipline.getSchedules().stream().filter(s -> rating >= s.getMinRating() && (s.getMaxRatingExclusive() == null || rating < s.getMaxRatingExclusive())).findFirst().orElseThrow();
    }
}
