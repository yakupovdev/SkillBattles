package com.skillbattles.backend.scheduler;
import com.skillbattles.backend.processor.RatingProcessor;
import com.skillbattles.backend.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.context.annotation.Profile;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
@Component @Profile("!question-import") @RequiredArgsConstructor
@ConditionalOnProperty(name="app.season.scheduling.enabled",havingValue="true",matchIfMissing=true)
public class SeasonScheduler {
    private final UserService users;
    private final RatingProcessor ratings;
    @Scheduled(fixedDelayString="${app.season.scan-ms:60000}")
    public void rollover() {users.activeIds().forEach(ratings::prepare);}
}
