package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.SubscriptionDto;
import com.skillbattles.backend.service.SubscriptionService;
import com.skillbattles.backend.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import java.util.UUID;
@Component @RequiredArgsConstructor
public class SubscriptionProcessorImpl implements SubscriptionProcessor {
    private final UserService users;
    private final SubscriptionService subscriptions;
    @Override public SubscriptionDto current(UUID id){users.getById(id);return subscriptions.current(id);}
}
