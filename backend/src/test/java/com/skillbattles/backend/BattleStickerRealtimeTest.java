package com.skillbattles.backend;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.processor.*;
import com.skillbattles.backend.mapper.*;
import com.skillbattles.backend.service.*;
import org.junit.jupiter.api.Test;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;
import org.springframework.transaction.PlatformTransactionManager;
import java.time.*;
import java.util.*;
import static org.mockito.Mockito.*;
import static org.assertj.core.api.Assertions.*;

class BattleStickerRealtimeTest {
    final RealtimeSessionService sessions = mock(RealtimeSessionService.class);
    final SimpMessagingTemplate messaging = mock(SimpMessagingTemplate.class);
    final ThreadPoolTaskExecutor executor = mock(ThreadPoolTaskExecutor.class);
    final BattleService battles = mock(BattleService.class);
    final RealtimeProcessorImpl realtime = new RealtimeProcessorImpl(battles, mock(BattleProcessor.class), mock(BattleSnapshotMapper.class), sessions, messaging,
            Clock.systemUTC(), mock(PlatformTransactionManager.class), executor, mock(MatchmakingMapper.class), mock(BattleAccessProcessor.class), mock(MatchmakingProcessor.class));
    BattleStickerAcceptedEvent event() {
        UUID battle = UUID.randomUUID();
        return new BattleStickerAcceptedEvent(UUID.randomUUID(), new RealtimeEvent<>(UUID.randomUUID(), "BATTLE_STICKER", battle, 1, BattleFixtures.START,
                new BattleStickerData(battle, UUID.randomUUID(), UUID.randomUUID(), "gg", BattleFixtures.START)));
    }
    @Test void queuedEventCannotLeakIntoReplacementSession() {
        var event = event(); var target = new RealtimeTargetDto(event.opponentUserId(), "old");
        when(sessions.target(event.opponentUserId())).thenReturn(Optional.of(target));
        List<Runnable> queued = new ArrayList<>(); doAnswer(call -> { queued.add(call.getArgument(0)); return null; }).when(executor).execute(any(Runnable.class));
        realtime.battleStickerAccepted(event); assertThat(queued).hasSize(1);
        when(sessions.isCurrent("old")).thenReturn(false); queued.getFirst().run();
        verifyNoInteractions(messaging, battles);
    }
    @Test void rejectedQueueAndTransportFailureAreBestEffortWithoutDbWork() {
        var event = event(); when(sessions.target(event.opponentUserId())).thenReturn(Optional.of(new RealtimeTargetDto(event.opponentUserId(), "live")));
        doThrow(new org.springframework.core.task.TaskRejectedException("test drop")).when(executor).execute(any(Runnable.class));
        assertThatCode(() -> realtime.battleStickerAccepted(event)).doesNotThrowAnyException();
        doAnswer(call -> { ((Runnable) call.getArgument(0)).run(); return null; }).when(executor).execute(any(Runnable.class));
        when(sessions.isCurrent("live")).thenReturn(true);
        doThrow(new IllegalStateException("test transport drop")).when(messaging).convertAndSendToUser(anyString(), anyString(), any(), anyMap());
        assertThatCode(() -> realtime.battleStickerAccepted(event)).doesNotThrowAnyException(); verifyNoInteractions(battles);
    }
    @Test void absentSubscriberCreatesNoDeliveryTaskOrDbRead() {
        var event = event(); when(sessions.target(event.opponentUserId())).thenReturn(Optional.empty());
        realtime.battleStickerAccepted(event); verifyNoInteractions(executor, messaging, battles);
    }
}
