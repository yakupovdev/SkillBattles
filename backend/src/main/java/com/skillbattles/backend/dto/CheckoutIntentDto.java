package com.skillbattles.backend.dto;
import lombok.*;
import java.time.*;
import java.util.*;
@Data @NoArgsConstructor @AllArgsConstructor
public class CheckoutIntentDto {
    private String planCode;
    private Instant reservedUntil;
    private CheckoutDto checkout;
}
