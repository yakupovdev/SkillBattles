package com.skillbattles.backend.dto;
import lombok.*;
import java.time.*;
import java.util.*;
@Data @NoArgsConstructor @AllArgsConstructor
public class BillingAccountDto {
    private UUID userId;
    private String customerId;
    private String subscriptionId;
    private String planCode;
    private String status;
    private Instant currentPeriodStart;
    private Instant currentPeriodEnd;
    private boolean cancelAtPeriodEnd;
    private boolean paid;
    private boolean proActive;
    private int version;
    private Map<UUID,CheckoutIntentDto> checkouts;
}
