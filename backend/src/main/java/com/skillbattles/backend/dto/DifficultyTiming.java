package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import io.swagger.v3.oas.annotations.media.Schema;
import java.util.*;

@Getter @Setter
public class DifficultyTiming {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private Difficulty difficulty;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int limitSeconds;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int basePoints;
}
