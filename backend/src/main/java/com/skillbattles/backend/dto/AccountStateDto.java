package com.skillbattles.backend.dto;
import lombok.*;
import java.time.*;
import java.util.*;
@Data @NoArgsConstructor @AllArgsConstructor
public class AccountStateDto {
    private UserDto user;
    private SubscriptionDto subscription;
    private LimitsDto limits;
    private StreaksDto streaks;
}
