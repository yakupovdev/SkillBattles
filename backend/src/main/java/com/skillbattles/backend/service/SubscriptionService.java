package com.skillbattles.backend.service;
import com.skillbattles.backend.dto.*;
import java.util.*;
public interface SubscriptionService {
    void initialize(UUID userId);
    SubscriptionDto current(UUID userId);
    EntitlementsDto entitlements(UUID userId);
    Map<UUID,Boolean> proFlags(Collection<UUID> ids);
    Map<UUID,Boolean> lockProFlags(Collection<UUID> ids);
    void changed(UUID userId);
}
