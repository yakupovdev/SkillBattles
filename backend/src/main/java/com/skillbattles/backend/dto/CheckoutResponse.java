package com.skillbattles.backend.dto;
import lombok.*;
import java.time.*;
import java.util.*;
@Data @NoArgsConstructor @AllArgsConstructor
@io.swagger.v3.oas.annotations.media.Schema(requiredProperties={"checkoutSessionId","url","expiresAt"})
public class CheckoutResponse {
    private String checkoutSessionId;
    private String url;
    private Instant expiresAt;
}
