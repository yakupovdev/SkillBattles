package com.skillbattles.backend.dto;
import lombok.*;
import java.time.*;
import java.util.*;
@Data @NoArgsConstructor @AllArgsConstructor
public class AnswerAccessDto {
    private boolean canViewCorrectAnswers;
    private boolean canViewExplanations;
    private String requiredPlan;
}
