package com.skillbattles.backend.scheduler;
import com.skillbattles.backend.processor.BattleStickerProcessor;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Profile;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
@Component @Profile("!question-import") @RequiredArgsConstructor
public class BattleStickerScheduler {
    private final BattleStickerProcessor processor;
    @Scheduled(fixedDelay = 30000, initialDelay = 30000)
    public void cleanExpired() { processor.cleanExpired(); }
}
