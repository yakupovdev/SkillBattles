package com.skillbattles.backend.dto;
import lombok.*;
import java.time.*;
import java.util.*;
@Data @NoArgsConstructor @AllArgsConstructor
public class SubscriptionDto {
    private String planCode;
    private String status;
    private String billingMode="NONE";
    @io.swagger.v3.oas.annotations.media.Schema(nullable=true) private Instant currentPeriodStart;
    @io.swagger.v3.oas.annotations.media.Schema(nullable=true) private Instant currentPeriodEnd;
    private boolean cancelAtPeriodEnd;
    private EntitlementsDto entitlements;
}
