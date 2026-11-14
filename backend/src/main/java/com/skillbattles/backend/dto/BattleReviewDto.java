package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Getter @Setter
public class BattleReviewDto {
    private UUID battleId;
    private Subject subject;
    private BattleMode mode;
    private List<ReviewRoundDto> rounds;
}
