package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.*;
import java.util.*;
public interface BillingProcessor {
    List<SubscriptionPlanDto> plans();
    SubscriptionDto current(UUID userId);
    CheckoutDto checkout(UUID userId,String plan,UUID requestId);
    PortalDto portal(UUID userId);
    void webhook(byte[] raw,String signature);
}
