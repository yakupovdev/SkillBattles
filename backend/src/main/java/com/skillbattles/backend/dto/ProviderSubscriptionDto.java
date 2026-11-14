package com.skillbattles.backend.dto;
import lombok.*;
import java.time.*;
import java.util.*;
@Data @NoArgsConstructor @AllArgsConstructor
public class ProviderSubscriptionDto {
    private String customerId;
    private String subscriptionId;
    private String priceId;
    private String status;
    private Instant currentPeriodStart;
    private Instant currentPeriodEnd;
    private boolean cancelAtPeriodEnd;
    private boolean invoicePaid;
    private boolean liveMode;
}
