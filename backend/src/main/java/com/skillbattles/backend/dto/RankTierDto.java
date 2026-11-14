package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.util.*;

@Data @NoArgsConstructor @AllArgsConstructor
public class RankTierDto {
    private String code;
    private String displayName;
    private String leagueCode;
    private int floorRating;
    private Integer ceilingExclusive;
    private Integer divisionNumber;
}
