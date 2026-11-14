package com.skillbattles.backend.dto;
import lombok.*;
import java.time.*;
import java.util.*;
@Data @NoArgsConstructor @AllArgsConstructor
@io.swagger.v3.oas.annotations.media.Schema(requiredProperties={"canViewCorrectAnswers","canViewExplanations","requiredPlan"})
public class AnswerAccess {
    private boolean canViewCorrectAnswers;
    private boolean canViewExplanations;
    @io.swagger.v3.oas.annotations.media.Schema(nullable=true) private String requiredPlan;
}
