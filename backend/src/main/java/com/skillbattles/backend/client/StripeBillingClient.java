package com.skillbattles.backend.client;
import com.skillbattles.backend.dto.*;
import java.util.UUID;
public interface StripeBillingClient {
    boolean available();
    String customer(UUID userId);
    boolean hasSubscription(String customerId);
    CheckoutDto checkout(UUID userId,String customerId,String plan,UUID requestId);
    PortalDto portal(String customerId);
    ProviderSubscriptionDto latest(String customerId);
}
