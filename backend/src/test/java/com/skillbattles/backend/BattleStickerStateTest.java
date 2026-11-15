package com.skillbattles.backend;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.exception.*;
import com.skillbattles.backend.service.*;
import com.skillbattles.backend.processor.*;
import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.*;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.transaction.*;
import org.springframework.transaction.support.SimpleTransactionStatus;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import static com.skillbattles.backend.BattleFixtures.*;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

class BattleStickerStateTest {
    final MutableClock clock = new MutableClock();
    final BattleStickerStateServiceImpl state = new BattleStickerStateServiceImpl(clock);
    final BattleDto battle = waiting(2, BattleMode.RANKED, 1000, 1000);
    final UUID a = player(battle, 0), b = player(battle, 1);
    BattleStickerCommandDto command(String id) { return new BattleStickerCommandDto(id, UUID.randomUUID()); }
    @ParameterizedTest @ValueSource(strings = {"gg", "fire", "facepalm", "lol", "hmm", "too_slow", "ez", "wait_what", "crying"})
    void exactNineIdsHaveServerTimesAndOpponentOnlyEvent(String id) {
        var accepted = state.accept(battle, a, command(id));
        assertThat(accepted.receipt().getSentAt()).isEqualTo(START);
        assertThat(accepted.receipt().getNextAllowedAt()).isEqualTo(START.plusSeconds(4));
        assertThat(accepted.event().opponentUserId()).isEqualTo(b);
        assertThat(accepted.event().envelope().version()).isEqualTo(1);
        assertThat(accepted.event().envelope().occurredAt()).isEqualTo(START);
        assertThat(accepted.event().envelope().resourceId()).isEqualTo(battle.getId());
    }
    @ParameterizedTest @EnumSource(BattlePhase.class)
    void phasePolicyWithoutEngineMutation(BattlePhase phase) {
        battle.setPhase(phase); int version = battle.getVersion();
        if (phase == BattlePhase.FINISHED || phase == BattlePhase.CANCELLED)
            assertThatThrownBy(() -> state.accept(battle, a, command("gg"))).isInstanceOfSatisfying(BusinessException.class, e -> assertThat(e.getCode()).isEqualTo("STICKERS_NOT_ALLOWED"));
        else assertThat(state.accept(battle, a, command("gg")).event()).isNotNull();
        assertThat(battle.getVersion()).isEqualTo(version);
    }
    @ParameterizedTest @ValueSource(strings = {"GG", " gg", "gg ", "future_id", "🔥"})
    void invalidIdsDoNotConsumeSlot(String id) {
        assertThatThrownBy(() -> state.accept(battle, a, command(id))).isInstanceOfSatisfying(BusinessException.class, e -> assertThat(e.getCode()).isEqualTo("INVALID_STICKER_ID"));
        assertThat(state.accept(battle, a, command("gg")).event().envelope().version()).isEqualTo(1);
    }
    @Test void exactCooldownBoundariesAcrossStickerAndBattleAndIndependentUser() {
        state.accept(battle, a, command("gg"));
        var other = waiting(2, BattleMode.PRIVATE, 1000, 1000); other.getState().getPlayers().getFirst().setId(a);
        clock.set(START.plusMillis(3999));
        assertThatThrownBy(() -> state.accept(other, a, command("fire"))).isInstanceOfSatisfying(StickerCooldownException.class, e -> {
            assertThat(e.getRetryAfter()).isEqualTo(1); assertThat(e.getResetsAt()).isEqualTo(START.plusSeconds(4));
        });
        assertThat(state.accept(battle, b, command("lol")).event().envelope().version()).isEqualTo(2);
        clock.set(START.plusSeconds(4)); assertThat(state.accept(other, a, command("fire")).event()).isNotNull();
    }
    @Test void ceilRetryAfterPreservesSubMillisecondPrecision() {
        assertThat(new StickerCooldownException(START.plusMillis(1250), START.plusSeconds(4)).getRetryAfter()).isEqualTo(3);
        assertThat(new StickerCooldownException(START.plusSeconds(1).minusNanos(1), START.plusSeconds(4)).getRetryAfter()).isEqualTo(4);
    }
    @Test void retryDoesNotEmitOrAllocateOrExtendCooldownIncludingTerminal() {
        var command = command("gg"); var first = state.accept(battle, a, command);
        clock.set(START.plusSeconds(1)); battle.setPhase(BattlePhase.FINISHED);
        var replay = state.accept(battle, a, command);
        assertThat(replay.receipt()).isEqualTo(first.receipt()); assertThat(replay.event()).isNull();
        assertThatThrownBy(() -> state.accept(battle, a, new BattleStickerCommandDto("fire", command.getSubmissionId()))).isInstanceOfSatisfying(BusinessException.class, e -> assertThat(e.getCode()).isEqualTo("IDEMPOTENCY_CONFLICT"));
        var other = waiting(2, BattleMode.PRIVATE, 1000, 1000); other.getState().getPlayers().getFirst().setId(a);
        assertThatThrownBy(() -> state.accept(other, a, command)).isInstanceOfSatisfying(BusinessException.class, e -> assertThat(e.getCode()).isEqualTo("IDEMPOTENCY_CONFLICT"));
        battle.setPhase(BattlePhase.REVEAL); clock.set(START.plusSeconds(4));
        assertThat(state.accept(battle, a, command("fire")).event().envelope().version()).isEqualTo(2);
    }
    @Test void receiptExpiresAt120SecondsButActiveSequenceSurvivesQuietCleanupAndRestartClearsIt() {
        var command = command("gg"); var first = state.accept(battle, a, command);
        clock.set(START.plusSeconds(120).minusNanos(1)); state.cleanExpired();
        assertThat(state.accept(battle, a, command).receipt()).isEqualTo(first.receipt());
        clock.set(START.plusSeconds(120)); state.cleanExpired();
        assertThat(state.accept(battle, a, command).event().envelope().version()).isEqualTo(2);
        clock.set(START.plusSeconds(240)); state.cleanExpired();
        assertThat(state.sequenceCleanupCandidates()).hasSize(1);
        assertThat(state.accept(battle, b, command("gg")).event().envelope().version()).isEqualTo(3);
        assertThat(new BattleStickerStateServiceImpl(clock).accept(battle, a, command).event().envelope().version()).isEqualTo(1);
    }
    @Test void terminalCleanupWaitsForInflightValidatedSend() {
        state.accept(battle, a, command("gg")); state.beginBattleRead(battle.getId());
        state.forgetTerminalSequence(battle.getId());
        assertThat(state.accept(battle, b, command("gg")).event().envelope().version()).isEqualTo(2);
        state.endBattleRead(battle.getId()); assertThat(state.sequenceCleanupCandidates()).isEmpty();
    }
    @Test void concurrentSameUserAcceptsOnceAndOtherUserHasIndependentSlot() throws Exception {
        List<Callable<String>> actions = List.of(() -> attempt(a), () -> attempt(a), () -> attempt(b));
        var gate = new CountDownLatch(1);
        try (var executor = Executors.newFixedThreadPool(3)) {
            var futures = actions.stream().map(action -> executor.submit(() -> { gate.await(); return action.call(); })).toList(); gate.countDown();
            List<String> results = new ArrayList<>(); for (var future : futures) results.add(future.get(5, TimeUnit.SECONDS));
            assertThat(results).containsExactlyInAnyOrder("OK", "OK", "STICKER_COOLDOWN");
        }
    }
    @Test void concurrentIdenticalRetryGetsExactlyOneEvent() throws Exception {
        var command = command("gg"); var gate = new CountDownLatch(1);
        try (var executor = Executors.newFixedThreadPool(2)) {
            var f = executor.submit(() -> { gate.await(); return state.accept(battle, a, command); });
            var g = executor.submit(() -> { gate.await(); return state.accept(battle, a, command); }); gate.countDown();
            var one = f.get(5, TimeUnit.SECONDS); var two = g.get(5, TimeUnit.SECONDS);
            assertThat(one.receipt()).isEqualTo(two.receipt());
            assertThat(java.util.stream.Stream.of(one, two).filter(v -> v.event() != null).count()).isEqualTo(1);
        }
    }
    @Test void failedReadOrCommitNeverConsumesSlotAndPostAcceptanceQueueFailureNeverUndoesReceipt() {
        var battles = mock(BattleService.class); var publisher = mock(ApplicationEventPublisher.class); var tx = mock(PlatformTransactionManager.class);
        when(tx.getTransaction(any())).thenReturn(new SimpleTransactionStatus());
        when(battles.getForParticipant(battle.getId(), a)).thenThrow(new IllegalStateException()).thenReturn(battle);
        var processor = new BattleStickerProcessorImpl(battles, state, publisher, tx); var command = command("gg");
        assertThatThrownBy(() -> processor.send(battle.getId(), a, command)).isInstanceOf(IllegalStateException.class);
        verifyNoInteractions(publisher);
        doThrow(new UnexpectedRollbackException("test read rollback")).doNothing().when(tx).commit(any());
        assertThatThrownBy(() -> processor.send(battle.getId(), a, command)).isInstanceOf(UnexpectedRollbackException.class);
        verifyNoInteractions(publisher);
        doThrow(new org.springframework.core.task.TaskRejectedException("test drop")).when(publisher).publishEvent(any(Object.class));
        var receipt = processor.send(battle.getId(), a, command);
        assertThat(processor.send(battle.getId(), a, command)).isEqualTo(receipt);
        verify(publisher, times(1)).publishEvent(any(Object.class));
        verify(battles, never()).save(any()); verify(battles, never()).lock(any());
    }
    String attempt(UUID sender) {
        try { state.accept(battle, sender, command("gg")); return "OK"; } catch (BusinessException e) { return e.getCode(); }
    }
}
