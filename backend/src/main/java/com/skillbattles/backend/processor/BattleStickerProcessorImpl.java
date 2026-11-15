package com.skillbattles.backend.processor;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.BattlePhase;
import com.skillbattles.backend.exception.NotFoundException;
import com.skillbattles.backend.service.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Component;
import org.springframework.transaction.*;
import org.springframework.transaction.annotation.*;
import org.springframework.transaction.support.TransactionTemplate;
import java.util.UUID;

@Slf4j @Component
public class BattleStickerProcessorImpl implements BattleStickerProcessor {
    private final BattleService battles;
    private final BattleStickerStateService state;
    private final ApplicationEventPublisher events;
    private final TransactionTemplate read;
    public BattleStickerProcessorImpl(BattleService battles, BattleStickerStateService state, ApplicationEventPublisher events, PlatformTransactionManager transactions) {
        this.battles = battles; this.state = state; this.events = events;
        read = new TransactionTemplate(transactions);
        read.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
        read.setReadOnly(true);
    }
    @Override @Transactional(propagation = Propagation.NOT_SUPPORTED)
    public BattleStickerReceiptDto send(UUID battleId, UUID sender, BattleStickerCommandDto command) {
        state.beginBattleRead(battleId);
        try {
            // Complete the authoritative owned read BEFORE accepting ephemeral state. No engine tick or write lock.
            BattleDto battle = read.execute(status -> battles.getForParticipant(battleId, sender));
            var accepted = state.accept(battle, sender, command);
            if (accepted.event() != null) {
                try { events.publishEvent(accepted.event()); }
                catch (RuntimeException ex) { log.warn("Sticker notification dropped: {}", ex.getClass().getSimpleName()); }
            }
            return accepted.receipt();
        } finally { state.endBattleRead(battleId); }
    }
    @Override public void cleanExpired() {
        state.cleanExpired();
        for (var candidate : state.sequenceCleanupCandidates()) {
            try {
                var battle = battles.getForParticipant(candidate.battleId(), candidate.participantId());
                if (battle.getPhase() == BattlePhase.FINISHED || battle.getPhase() == BattlePhase.CANCELLED) state.forgetTerminalSequence(candidate.battleId());
            } catch (NotFoundException ex) { state.forgetTerminalSequence(candidate.battleId()); }
            catch (RuntimeException ex) { log.warn("Sticker maintenance read failed: {}", ex.getClass().getSimpleName()); }
        }
    }
}
