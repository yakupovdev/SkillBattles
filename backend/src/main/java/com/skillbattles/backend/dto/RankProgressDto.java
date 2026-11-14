package com.skillbattles.backend.dto;
import lombok.*;
@Data @NoArgsConstructor @AllArgsConstructor
public class RankProgressDto {
    private String rankCode;
    private String rankName;
    private String leagueCode;
    private int divisionRpCurrent;
    @io.swagger.v3.oas.annotations.media.Schema(nullable = true)
    private Integer divisionRpTarget;
    private int floorRating;
    @io.swagger.v3.oas.annotations.media.Schema(nullable = true)
    private Integer ceilingExclusive;
}
