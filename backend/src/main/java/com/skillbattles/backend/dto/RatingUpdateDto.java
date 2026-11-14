package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RatingUpdateDto {
    private UUID userId;
    private String disciplineCode;
    private int before;
    private int after;
    private String seasonId;
    private int completedMatchesBefore;
}

