package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.util.*;

@Data @NoArgsConstructor @AllArgsConstructor
public class DifficultyScheduleDto {
    private int minRating;
    private Integer maxRatingExclusive;
    private List<Difficulty> roundDifficulties;
}
