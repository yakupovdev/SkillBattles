package com.skillbattles.backend.dto;
import lombok.*;
import java.time.*;
import java.util.*;
@Data @NoArgsConstructor @AllArgsConstructor
@io.swagger.v3.oas.annotations.media.Schema(requiredProperties={"user","subscription","limits","streaks"})
public class AccountState {
    private UserResponse user;
    private SubscriptionResponse subscription;
    private LimitsResponse limits;
    private Streaks streaks;
}
