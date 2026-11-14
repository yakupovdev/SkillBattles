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
    private Subject subject;
    private int before;
    private int after;
}

