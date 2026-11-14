package com.skillbattles.backend.processor;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.mapper.BattleSnapshotMapper;
import com.skillbattles.backend.mapper.MatchmakingMapper;
import com.skillbattles.backend.service.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Profile;
import org.springframework.context.event.EventListener;
import org.springframework.messaging.simp.*;
import org.springframework.stereotype.Component;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;
import org.springframework.core.task.TaskRejectedException;
import org.springframework.transaction.*;
import org.springframework.transaction.support.TransactionTemplate;
import java.time.Clock;
import java.util.*;

@Slf4j
@Component
@Profile("!question-import")
public class RealtimeProcessorImpl implements RealtimeProcessor {
    private final BattleService battles;
    private final BattleProcessor processor;
    private final BattleSnapshotMapper mapper;
    private final RealtimeSessionService sessions;
    private final SimpMessagingTemplate messaging;
    private final Clock clock;
    private final ThreadPoolTaskExecutor executor;
    private final TransactionTemplate committedRead;
    private final MatchmakingMapper matchmakingMapper;

    public RealtimeProcessorImpl(BattleService battles, BattleProcessor processor, BattleSnapshotMapper mapper,
            RealtimeSessionService sessions, SimpMessagingTemplate messaging, Clock clock, PlatformTransactionManager transactions,
            ThreadPoolTaskExecutor realtimeEventExecutor, MatchmakingMapper matchmakingMapper) {
        this.battles = battles; this.processor = processor; this.mapper = mapper;
        this.sessions = sessions; this.messaging = messaging; this.clock = clock;
        this.executor = realtimeEventExecutor;
        this.matchmakingMapper = matchmakingMapper;
        this.committedRead = new TransactionTemplate(transactions);
        this.committedRead.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
    }

    @Override
    @EventListener
    public void presenceChanged(PresenceChangedEvent event) {
        enqueue(() -> updatePresence(event));
    }

    private void updatePresence(PresenceChangedEvent event) {
        try {
            for (UUID id : battles.activeIdsForUser(event.userId())) {
                try { processor.tick(id); }
                catch (RuntimeException ex) { log.error("Presence update failed for battle {}: {}", id, ex.getClass().getSimpleName()); }
            }
        } catch (RuntimeException ex) {
            // Database availability must never prevent a transport from closing at token expiry.
            log.error("Presence notification failed: {}", ex.getClass().getSimpleName());
        }
    }

    @Override
    @EventListener
    public void battleChanged(BattleChangedEvent event) {
        if (!sessions.hasSubscribers()) return;
        enqueue(() -> publishBattle(event));
    }

    private void publishBattle(BattleChangedEvent event) {
        try {
            // The originating afterCommit still has transaction-bound resources. Start a fresh read,
            // finish it before publishing, and never advance/mutate state while building an event.
            List<Delivery> deliveries = committedRead.execute(status -> {
                BattleDto battle = battles.lock(event.battleId());
                UUID eventId = UUID.randomUUID();
                List<Delivery> result = new ArrayList<>();
                for (var player : battle.getState().getPlayers()) {
                    sessions.target(player.getId()).ifPresent(target -> {
                        BattleSnapshot snapshot = mapper.toResponse(mapper.snapshot(battle, player.getId(), clock.instant()));
                        result.add(new Delivery(target, new RealtimeEvent<>(eventId, "BATTLE_CHANGED", battle.getId(),
                                snapshot.getVersion(), event.occurredAt(), snapshot)));
                    });
                }
                return result;
            });
            if (deliveries == null) return;
            for (Delivery delivery : deliveries) {
                if (!sessions.isCurrent(delivery.target().sessionId())) continue;
                SimpMessageHeaderAccessor headers = SimpMessageHeaderAccessor.create(SimpMessageType.MESSAGE);
                headers.setSessionId(delivery.target().sessionId());
                headers.setLeaveMutable(true);
                messaging.convertAndSendToUser(delivery.target().userId().toString(), "/queue/events", delivery.event(), headers.getMessageHeaders());
            }
        } catch (RuntimeException ex) {
            // Events are notifications, not durable commands. Clients recover via the REST snapshot.
            log.error("Battle notification failed for {}: {}", event.battleId(), ex.getClass().getSimpleName());
        }
    }

    @Override
    @EventListener
    public void activityChanged(ActivityChangedEvent event) {
        if (!sessions.hasSubscribers()) return;
        enqueue(() -> {
            try {
                List<UUID> users = new ArrayList<>();
                RealtimeEvent<?> envelope;
                if (event.entry() != null) {
                    var entry = event.entry(); users.add(entry.getUserId());
                    envelope = new RealtimeEvent<>(UUID.randomUUID(), "QUEUE_CHANGED", entry.getId(), entry.getVersion(), event.occurredAt(), matchmakingMapper.toResponse(entry));
                } else {
                    var duel = event.duel(); users.add(duel.getHost().getId());
                    if (duel.getGuest() != null) users.add(duel.getGuest().getId());
                    envelope = new RealtimeEvent<>(UUID.randomUUID(), "PRIVATE_DUEL_CHANGED", duel.getId(), duel.getVersion(), event.occurredAt(), matchmakingMapper.toResponse(duel));
                }
                for (UUID user : users) sessions.target(user).ifPresent(target -> {
                    SimpMessageHeaderAccessor headers = SimpMessageHeaderAccessor.create(SimpMessageType.MESSAGE);
                    headers.setSessionId(target.sessionId()); headers.setLeaveMutable(true);
                    messaging.convertAndSendToUser(user.toString(), "/queue/events", envelope, headers.getMessageHeaders());
                });
            } catch (RuntimeException ex) { log.error("Activity notification failed: {}", ex.getClass().getSimpleName()); }
        });
    }

    private void enqueue(Runnable action) {
        try { executor.execute(action); }
        catch (TaskRejectedException ex) {
            // Notifications are recoverable; transport expiry must never wait for database work.
            log.warn("Realtime work queue is full; REST snapshots recover current state.");
        }
    }

    private record Delivery(RealtimeTargetDto target, RealtimeEvent<?> event) { }
}
