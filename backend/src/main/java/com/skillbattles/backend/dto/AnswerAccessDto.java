package com.skillbattles.backend.dto;
import lombok.*;
import java.time.*;
import java.util.*;
@Data @NoArgsConstructor @AllArgsConstructor
public class AnswerAccessDto {
    private boolean canViewCorrectAnswer;
    private boolean canViewExplanation;
    private int entitlementVersion;
}
