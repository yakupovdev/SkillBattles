package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BattleResultPlayerDto {
    private UUID id;
    @com.fasterxml.jackson.annotation.JsonIgnore private boolean pro;
    private String nickname;
    private int score;
    private int correctCount;
    private int ratingBefore;
    private int ratingAfter;
    private int ratingDelta;
    @com.fasterxml.jackson.annotation.JsonProperty("kFactor")
    @Getter(onMethod_ = @com.fasterxml.jackson.annotation.JsonProperty("kFactor"))
    @Setter(onMethod_ = @com.fasterxml.jackson.annotation.JsonProperty("kFactor"))
    private int kFactor;
    private int calibrationMatchesRemaining;
    private String rankBefore;
    private String rankAfter;
}
