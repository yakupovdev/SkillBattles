package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.SubscriptionDto;
import java.util.UUID;
public interface SubscriptionProcessor {SubscriptionDto current(UUID userId);}
