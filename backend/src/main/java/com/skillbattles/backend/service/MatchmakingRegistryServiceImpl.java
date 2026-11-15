package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.*;
import java.time.Clock;
import java.util.concurrent.locks.ReentrantLock;
import java.util.function.Function;

/** Single-process account activity lock; memory becomes visible only after database commit. */
@Service
public class MatchmakingRegistryServiceImpl implements MatchmakingRegistryService {
    private final ReentrantLock lock = new ReentrantLock(true);
    private final TransactionTemplate transactions;
    private final ApplicationEventPublisher events;
    private final Clock clock;
    private MatchmakingStateDto committed = new MatchmakingStateDto();

    public MatchmakingRegistryServiceImpl(PlatformTransactionManager manager, ApplicationEventPublisher events, Clock clock) {
        transactions = new TransactionTemplate(manager); this.events = events; this.clock = clock;
    }

    @Override public boolean hasWaiting() {
        lock.lock();
        try {
            return committed.getDuelInvitations().values().stream().anyMatch(i->i.getStatus()==DuelInvitationStatus.PENDING) || committed.getRematches().values().stream().anyMatch(r -> r.getStatus().equals("WAITING")) || committed.getEntries().values().stream().anyMatch(entry -> entry.getStatus() == QueueStatus.SEARCHING)
                    || committed.getDuels().values().stream().anyMatch(duel -> duel.getStatus() == DuelStatus.WAITING);
        } finally { lock.unlock(); }
    }

    @Override public <T> T transact(Function<MatchmakingStateDto, T> operation) {
        lock.lock(); // Always before starting a production database transaction or locking user rows.
        boolean[] release = {true};
        try {
            return transactions.execute(status -> {
                MatchmakingStateDto state = (MatchmakingStateDto) TransactionSynchronizationManager.getResource(this);
                if (state == null) {
                    MatchmakingStateDto before = committed;
                    state = new MatchmakingStateDto(before);
                    MatchmakingStateDto staged = state;
                    TransactionSynchronizationManager.bindResource(this, state);
                    TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                        @Override public void afterCommit() {
                            committed = staged;
                            var at = clock.instant();
                            staged.getDuelInvitations().forEach((id,invitation)->{
                                if(!invitation.equals(before.getDuelInvitations().get(id)))events.publishEvent(new DuelInvitationChangedEvent(invitation,at));
                            });
                            staged.getRematches().forEach((id,rematch)->{
                                if(!rematch.equals(before.getRematches().get(id)))events.publishEvent(new RematchChangedEvent(rematch,at));
                            });
                            staged.getEntries().forEach((id, entry) -> {
                                if (!entry.equals(before.getEntries().get(id))) events.publishEvent(new ActivityChangedEvent(entry, null, at));
                            });
                            staged.getDuels().forEach((id, duel) -> {
                                if (!duel.equals(before.getDuels().get(id))) events.publishEvent(new ActivityChangedEvent(null, duel, at));
                            });
                        }
                        @Override public void afterCompletion(int completion) {
                            TransactionSynchronizationManager.unbindResource(MatchmakingRegistryServiceImpl.this);
                            lock.unlock();
                        }
                    });
                    release[0] = false; // Also retain the lock until completion of a caller's outer transaction.
                }
                return operation.apply(state);
            });
        } finally { if (release[0]) lock.unlock(); }
    }
}
