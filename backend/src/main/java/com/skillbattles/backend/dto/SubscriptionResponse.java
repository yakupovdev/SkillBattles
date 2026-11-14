package com.skillbattles.backend.dto;
import lombok.*;
import java.time.*;
import java.util.*;
@Data @NoArgsConstructor @AllArgsConstructor
@io.swagger.v3.oas.annotations.media.Schema(requiredProperties={"planCode","status","billingMode","currentPeriodStart","currentPeriodEnd","cancelAtPeriodEnd","entitlements"})
public class SubscriptionResponse {
    private String planCode;
    private String status;
    private String billingMode="TEST";
    @io.swagger.v3.oas.annotations.media.Schema(nullable=true) private Instant currentPeriodStart;
    @io.swagger.v3.oas.annotations.media.Schema(nullable=true) private Instant currentPeriodEnd;
    private boolean cancelAtPeriodEnd;
    private Entitlements entitlements;
}
