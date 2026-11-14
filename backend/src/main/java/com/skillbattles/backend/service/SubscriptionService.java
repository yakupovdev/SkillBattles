package com.skillbattles.backend.service;
import com.skillbattles.backend.dto.*;
import java.util.*;
public interface SubscriptionService {
    void initialize(UUID userId);
    BillingAccountDto account(UUID userId);
    Optional<UUID> owner(String customerId);
    SubscriptionDto current(UUID userId);
    EntitlementsDto entitlements(UUID userId);
    Map<UUID,Boolean> proFlags(Collection<UUID> ids);
    Map<UUID,Boolean> lockProFlags(Collection<UUID> ids);
    CheckoutIntentDto reserve(UUID userId,String plan,UUID requestId);
    void bindCustomer(UUID userId,String customerId);
    void checkoutCreated(UUID userId,UUID requestId,CheckoutDto dto);
    boolean processed(String eventId);
    void apply(UUID userId,String eventId,ProviderSubscriptionDto provider,String plan);
    void changed(UUID userId);
    void expire();
}
