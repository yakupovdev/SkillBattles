package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import io.swagger.v3.oas.annotations.media.Schema;
import java.util.*;

@Getter @Setter
public class RankTier {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private String code;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private String displayName;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private String leagueCode;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private int floorRating;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private Integer ceilingExclusive;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private Integer divisionNumber;
}
