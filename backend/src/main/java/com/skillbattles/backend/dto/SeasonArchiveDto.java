package com.skillbattles.backend.dto;
import lombok.*;
import java.util.UUID;
@Data @NoArgsConstructor @AllArgsConstructor
public class SeasonArchiveDto {
    private UUID userId;
    private String seasonId;
    private SeasonDto season;
    private String disciplineCode;
    private int peakRating;
    private String peakRankCode;
    private int finalRating;
}
