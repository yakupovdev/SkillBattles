package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.util.*;

@Data @NoArgsConstructor @AllArgsConstructor
public class DifficultyTimingDto {
    private Difficulty difficulty;
    private java.math.BigDecimal timeMultiplier;
    private int basePoints;
}
