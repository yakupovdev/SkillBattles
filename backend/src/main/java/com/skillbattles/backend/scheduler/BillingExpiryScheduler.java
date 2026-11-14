package com.skillbattles.backend.scheduler;
import com.skillbattles.backend.service.SubscriptionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.context.annotation.Profile;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
@Component @Profile("!question-import") @RequiredArgsConstructor
@ConditionalOnProperty(name="app.billing.scheduling.enabled",havingValue="true",matchIfMissing=true)
public class BillingExpiryScheduler {
    private final SubscriptionService subscriptions;
    @Scheduled(fixedDelayString="${app.billing.expiry-scan-ms:1000}") public void expire(){subscriptions.expire();}
}
