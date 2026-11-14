package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.service.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;
@Component @RequiredArgsConstructor
public class AccountProcessorImpl implements AccountProcessor {
    private final UserService users;private final SubscriptionService subscriptions;private final UsageProcessor usage;private final StreakService streaks;
    @Override @Transactional(readOnly=true) public AccountStateDto state(UUID user){var profile=users.getById(user);var sub=subscriptions.current(user);profile.setPro(sub.getEntitlements().isPro());return new AccountStateDto(profile,sub,usage.limits(user,sub),streaks.current(user));}
}
