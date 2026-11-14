package com.skillbattles.backend.dto;
import lombok.*;
import java.time.*;
import java.util.*;
@Data @NoArgsConstructor @AllArgsConstructor
public class CheckoutDto {
    private String checkoutSessionId;
    private String url;
    private Instant expiresAt;
}
