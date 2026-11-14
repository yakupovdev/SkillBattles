package com.skillbattles.backend.dto;
import lombok.*;
import java.time.*;
import java.util.*;
@Data @NoArgsConstructor @AllArgsConstructor
@io.swagger.v3.oas.annotations.media.Schema(requiredProperties={"canViewCorrectAnswer","canViewExplanation","entitlementVersion"})
public class AnswerAccess {
    private boolean canViewCorrectAnswer;
    private boolean canViewExplanation;
    private int entitlementVersion;
}
