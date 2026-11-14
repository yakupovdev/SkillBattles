package com.skillbattles.backend.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.skillbattles.backend.BattleFixtures;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.exception.*;
import com.skillbattles.backend.mapper.BattleSnapshotMapper;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.mapstruct.factory.Mappers;
import java.time.*;
import java.util.*;
import static org.assertj.core.api.Assertions.*;
import static com.skillbattles.backend.BattleFixtures.*;

class BattleEngineTest {
    private final BattleEngine engine = new BattleEngineImpl();
    private final BattleSnapshotMapper mapper = Mappers.getMapper(BattleSnapshotMapper.class);

    private BattleDto started(int rounds, BattleMode mode) {
        BattleDto battle = waiting(rounds, mode, 1000, 1000);
        engine.ready(battle, player(battle, 0), START);
        int readyVersion = battle.getVersion();
        engine.ready(battle, player(battle, 0), START);
        assertThat(battle.getVersion()).isEqualTo(readyVersion);
        engine.ready(battle, player(battle, 1), START);
        assertThat(battle.getPhase()).isEqualTo(BattlePhase.COUNTDOWN);
        engine.advance(battle, START.plusSeconds(3));
        return battle;
    }

    @ParameterizedTest
    @CsvSource({"0,100", "1,99", "99,99", "100,99", "5000,50", "9900,1", "9999,0"})
    void bonusUsesServerTimeAndFloorWithoutStreakMultiplier(long elapsedMs, int expectedBonus) {
        BattleDto battle = started(1, BattleMode.RANKED);
        battle.getState().getPlayers().getFirst().setStreak(50);
        Instant accepted = round(battle).getStartedAt().plusMillis(elapsedMs);
        engine.answer(battle, player(battle, 0), answer(battle, true), accepted, accepted);
        BattleAnswerDto saved = round(battle).getAnswers().getFirst();
        assertThat(saved.getSpeedBonus()).isEqualTo(expectedBonus);
        assertThat(saved.getPoints()).isEqualTo(1000 + expectedBonus);
        assertThat(battle.getState().getPlayers().getFirst().getScore()).isZero();
    }

    @Test
    void exactDeadlineIsLateAndTimeoutHasNoSelectionOrElapsedTime() {
        BattleDto battle = started(1, BattleMode.RANKED);
        Instant deadline = round(battle).getDeadline();
        AnswerDto answer = answer(battle, true);
        assertCode(() -> engine.answer(battle, player(battle, 0), answer, deadline, deadline), "ROUND_CLOSED");
        assertThat(battle.getPhase()).isEqualTo(BattlePhase.REVEAL);
        assertThat(round(battle).getAnswers()).allSatisfy(item -> {
            assertThat(item.isTimedOut()).isTrue();
            assertThat(item.getSelectedOptionId()).isNull();
            assertThat(item.getElapsedMs()).isNull();
            assertThat(item.getPoints()).isZero();
        });
        assertThat(battle.getNextRoundStartsAt()).isNull();
        engine.advance(battle, deadline.plusSeconds(5));
        assertThat(battle.getPhase()).isEqualTo(BattlePhase.FINISHED);
        assertThat(battle.getResult().getWinnerUserId()).isNull();
        assertThat(battle.getResult().getPlayers()).allSatisfy(item -> assertThat(item.getRatingDelta()).isZero());
    }

    @Test
    void timelyQueuedRequestUsesEntryTimeButCannotReopenCommittedRound() {
        BattleDto battle = started(1, BattleMode.RANKED);
        Instant deadline = round(battle).getDeadline();
        AnswerDto command = answer(battle, true);
        var receipt = engine.answer(battle, player(battle, 0), command, deadline.minusMillis(1), deadline.plusSeconds(1));
        assertThat(receipt.getAcceptedAt()).isEqualTo(deadline.minusMillis(1));
        assertThat(round(battle).getAnswers().getFirst().getPoints()).isEqualTo(1000);
        BattleDto closed = started(1, BattleMode.RANKED);
        AnswerDto late = answer(closed, true);
        engine.advance(closed, round(closed).getDeadline());
        assertCode(() -> engine.answer(closed, player(closed, 0), late, round(closed).getDeadline().minusMillis(1), deadline.plusSeconds(1)), "ROUND_CLOSED");
    }

    @Test
    void replayReturnsOriginalReceiptAcrossRoundsAndTerminalState() {
        BattleDto battle = started(2, BattleMode.RANKED);
        AnswerDto command = answer(battle, true);
        var receipt = engine.answer(battle, player(battle, 0), command, START.plusSeconds(4), START.plusSeconds(4));
        assertThat(engine.answer(battle, player(battle, 0), command, START.plusSeconds(5), START.plusSeconds(5))).isEqualTo(receipt);
        AnswerDto conflicting = new AnswerDto(command.getRoundId(), UUID.randomUUID(), command.getSubmissionId());
        assertCode(() -> engine.answer(battle, player(battle, 0), conflicting, START.plusSeconds(5), START.plusSeconds(5)), "IDEMPOTENCY_CONFLICT");
        assertCode(() -> engine.answer(battle, player(battle, 1), command, START.plusSeconds(5), START.plusSeconds(5)), "IDEMPOTENCY_CONFLICT");
        assertCode(() -> engine.answer(battle, player(battle, 0), answer(battle, true), START.plusSeconds(5), START.plusSeconds(5)), "ANSWER_ALREADY_SUBMITTED");
        engine.advance(battle, START.plusSeconds(60));
        int version = battle.getVersion();
        assertThat(engine.answer(battle, player(battle, 0), command, START.plusSeconds(61), START.plusSeconds(61))).isEqualTo(receipt);
        engine.advance(battle, START.plusSeconds(600));
        assertThat(battle.getVersion()).isEqualTo(version);
    }

    @Test
    void wrongOptionAndWrongRoundAreRejectedWithoutAddingAnswer() {
        BattleDto battle = started(1, BattleMode.RANKED);
        assertCode(() -> engine.answer(battle, player(battle, 0), new AnswerDto(round(battle).getId(), UUID.randomUUID(), UUID.randomUUID()), START.plusSeconds(4), START.plusSeconds(4)), "INVALID_OPTION");
        assertCode(() -> engine.answer(battle, player(battle, 0), new AnswerDto(UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID()), START.plusSeconds(4), START.plusSeconds(4)), "INVALID_BATTLE_STATE");
        assertThat(round(battle).getAnswers()).isEmpty();
    }

    @Test
    void redactionIsPersonalAndDoesNotExposeFutureQuestionCorrectnessOrExplanation() throws Exception {
        BattleDto battle = started(2, BattleMode.RANKED);
        UUID first = player(battle, 0), second = player(battle, 1);
        engine.answer(battle, first, answer(battle, true), START.plusSeconds(4), START.plusSeconds(4));
        var owner = mapper.snapshot(battle, first, START.plusSeconds(4));
        var opponent = mapper.snapshot(battle, second, START.plusSeconds(4));
        assertThat(owner.getRound().getMySelectedOptionId()).isNotNull();
        assertThat(opponent.getRound().getMySelectedOptionId()).isNull();
        assertThat(opponent.getRound().getReveal()).isNull();
        assertThat(opponent.getPlayers().getFirst().getScore()).isZero();
        String json = new ObjectMapper().findAndRegisterModules().writeValueAsString(opponent);
        assertThat(json).doesNotContain("correctOptionId", "explanation", "acceptedAt", "speedBonus", "TEST ONLY question 1", "sessionId", "email");
        engine.answer(battle, second, answer(battle, false), START.plusSeconds(5), START.plusSeconds(5));
        assertThat(battle.getPhase()).isEqualTo(BattlePhase.REVEAL);
        assertThat(mapper.snapshot(battle, second, START.plusSeconds(5)).getRound().getReveal().getAnswers()).hasSize(2);
        assertThat(battle.getState().getPlayers().getFirst().getScore()).isEqualTo(1090);
        assertThat(battle.getState().getPlayers().get(1).getScore()).isZero();
    }

    @Test
    void delayedAndRepeatedTicksUsePersistedDeadlinesAndFinishExactlyOnce() {
        BattleDto battle = started(3, BattleMode.PRIVATE);
        engine.advance(battle, START.plusSeconds(48));
        assertThat(battle.getPhase()).isEqualTo(BattlePhase.FINISHED);
        assertThat(battle.getState().getRounds()).extracting(BattleRoundDto::getStartedAt)
                .containsExactly(START.plusSeconds(3), START.plusSeconds(18), START.plusSeconds(33));
        assertThat(battle.getResult().getFinishedAt()).isEqualTo(START.plusSeconds(48));
        int version = battle.getVersion();
        engine.advance(battle, START.plusSeconds(500));
        assertThat(battle.getVersion()).isEqualTo(version);
    }

    @Test
    void incompleteRoundDoesNotChangeRevealedScoreOnSurrender() {
        BattleDto battle = started(2, BattleMode.RANKED);
        engine.answer(battle, player(battle, 0), answer(battle, true), START.plusSeconds(4), START.plusSeconds(4));
        engine.surrender(battle, player(battle, 0), START.plusSeconds(5));
        assertThat(battle.getResult().getReason()).isEqualTo(CompletionReason.SURRENDER);
        assertThat(battle.getResult().getWinnerUserId()).isEqualTo(player(battle, 1));
        assertThat(round(battle).isCompleted()).isFalse();
        assertThat(battle.getResult().getPlayers()).allSatisfy(item -> assertThat(item.getScore()).isZero());
        assertThat(battle.getResult().getPlayers()).extracting(BattleResultPlayerDto::getRatingDelta).containsExactly(-16, 16);
        int version = battle.getVersion();
        engine.surrender(battle, player(battle, 1), START.plusSeconds(6));
        engine.interrupt(battle, START.plusSeconds(7));
        assertThat(battle.getVersion()).isEqualTo(version);
    }

    @Test
    void preStartSurrenderReadyTimeoutAndInterruptionNeverChangeRatings() {
        BattleDto battle = waiting(1, BattleMode.RANKED, 1000, 1000);
        engine.surrender(battle, player(battle, 0), START.plusSeconds(1));
        assertThat(battle.getPhase()).isEqualTo(BattlePhase.CANCELLED);
        assertThat(battle.getResult().getPlayers()).allSatisfy(item -> assertThat(item.getRatingDelta()).isZero());
        BattleDto timeout = waiting(1, BattleMode.RANKED, 1000, 1000);
        engine.advance(timeout, START.plusSeconds(30));
        assertThat(timeout.getResult().getReason()).isEqualTo(CompletionReason.READY_TIMEOUT);
        BattleDto interrupted = started(1, BattleMode.RANKED);
        engine.interrupt(interrupted, START.plusSeconds(5));
        assertThat(interrupted.getPhase()).isEqualTo(BattlePhase.CANCELLED);
        assertThat(interrupted.getResult().getReason()).isEqualTo(CompletionReason.SERVER_INTERRUPTION);
    }

    @Test
    void readinessCannotBypassLiveSubscription() {
        BattleDto battle = waiting(1, BattleMode.RANKED, 1000, 1000);
        engine.synchronizePresence(battle, Map.of(), START);
        assertCode(() -> engine.ready(battle, player(battle, 0), START), "REALTIME_CONNECTION_REQUIRED");
    }

    @Test
    void disconnectGraceDoesNotPauseAndExactReconnectDeadlineCannotSavePlayer() {
        BattleDto battle = started(5, BattleMode.RANKED);
        Map<UUID, PresenceDto> online = Map.of(player(battle, 1), new PresenceDto(UUID.randomUUID(), START.plusSeconds(3600)));
        engine.synchronizePresence(battle, online, START.plusSeconds(4));
        Instant originalDeadline = round(battle).getDeadline();
        assertThat(battle.getState().getPlayers().getFirst().getReconnectDeadline()).isEqualTo(START.plusSeconds(34));
        Map<UUID, PresenceDto> both = new HashMap<>(online);
        both.put(player(battle, 0), new PresenceDto(UUID.randomUUID(), START.plusSeconds(3600)));
        engine.synchronizePresence(battle, both, START.plusSeconds(33));
        assertThat(battle.getState().getPlayers().getFirst().isConnected()).isTrue();
        assertThat(battle.getState().getRounds().getFirst().getDeadline()).isEqualTo(originalDeadline);
        engine.synchronizePresence(battle, online, START.plusSeconds(35));
        engine.synchronizePresence(battle, both, START.plusSeconds(65));
        assertThat(battle.getResult().getReason()).isEqualTo(CompletionReason.DISCONNECT);
        assertThat(battle.getResult().getWinnerUserId()).isEqualTo(player(battle, 1));
    }

    @Test
    void bothOfflineCancelsAndJwtExpiryStartsGraceAtExpiry() {
        BattleDto battle = started(5, BattleMode.RANKED);
        battle.getState().getPlayers().forEach(player -> player.setSessionExpiresAt(START.plusSeconds(4)));
        engine.advance(battle, START.plusSeconds(34));
        assertThat(battle.getPhase()).isEqualTo(BattlePhase.CANCELLED);
        assertThat(battle.getResult().getReason()).isEqualTo(CompletionReason.BOTH_DISCONNECTED);
        assertThat(battle.getResult().getPlayers()).allSatisfy(player -> assertThat(player.getRatingDelta()).isZero());
    }

    @Test
    void normalCompletionBeforeLaterDisconnectExpiryWinsAndPrivateNeverRates() {
        BattleDto battle = started(1, BattleMode.PRIVATE);
        engine.synchronizePresence(battle, Map.of(), START.plusSeconds(4));
        engine.advance(battle, START.plusSeconds(100));
        assertThat(battle.getResult().getReason()).isEqualTo(CompletionReason.NORMAL);
        assertThat(battle.getResult().getFinishedAt()).isEqualTo(START.plusSeconds(18));
        assertThat(battle.getResult().getPlayers()).allSatisfy(player -> assertThat(player.getRatingDelta()).isZero());
    }

    @Test
    void ratingFloorReportsActualDeltas() {
        BattleDto battle = waiting(1, BattleMode.RANKED, 0, 0);
        engine.ready(battle, player(battle, 0), START);
        engine.ready(battle, player(battle, 1), START);
        engine.advance(battle, START.plusSeconds(3));
        engine.surrender(battle, player(battle, 1), START.plusSeconds(4));
        assertThat(battle.getResult().getPlayers()).extracting(BattleResultPlayerDto::getRatingDelta).containsExactly(16, 0);
    }

    static void assertCode(org.assertj.core.api.ThrowableAssert.ThrowingCallable action, String code) {
        assertThatThrownBy(action).isInstanceOfSatisfying(BusinessException.class, ex -> assertThat(ex.getCode()).isEqualTo(code));
    }

    @ParameterizedTest
    @CsvSource({"2,CANCELLED,0", "3,FINISHED,-16"})
    void surrenderAtCountdownBoundaryUsesServerState(long elapsed, BattlePhase expectedPhase, int expectedDelta) {
        BattleDto battle = waiting(1, BattleMode.RANKED, 1000, 1000);
        engine.ready(battle, player(battle, 0), START);
        engine.ready(battle, player(battle, 1), START);
        engine.surrender(battle, player(battle, 0), START.plusSeconds(elapsed));
        assertThat(battle.getPhase()).isEqualTo(expectedPhase);
        assertThat(battle.getResult().getPlayers().getFirst().getRatingDelta()).isEqualTo(expectedDelta);
    }

    @Test
    void unequalRatingDrawAdjustsEloFromFrozenRatings() {
        BattleDto battle = waiting(1, BattleMode.RANKED, 1200, 1600);
        engine.ready(battle, player(battle, 0), START);
        engine.ready(battle, player(battle, 1), START);
        engine.advance(battle, START.plusSeconds(18));
        assertThat(battle.getResult().getWinnerUserId()).isNull();
        assertThat(battle.getResult().getPlayers()).extracting(BattleResultPlayerDto::getRatingAfter).containsExactly(1213, 1587);
    }

    @Test
    void streakIncrementsOnCorrectAndResetsOnWrongWithoutChangingPriorScore() {
        BattleDto battle = started(2, BattleMode.RANKED);
        engine.answer(battle, player(battle, 0), answer(battle, true), START.plusSeconds(4), START.plusSeconds(4));
        engine.answer(battle, player(battle, 1), answer(battle, false), START.plusSeconds(4), START.plusSeconds(4));
        assertThat(battle.getState().getPlayers().getFirst().getStreak()).isEqualTo(1);
        engine.advance(battle, START.plusSeconds(9));
        engine.answer(battle, player(battle, 0), answer(battle, false), START.plusSeconds(10), START.plusSeconds(10));
        engine.answer(battle, player(battle, 1), answer(battle, true), START.plusSeconds(10), START.plusSeconds(10));
        assertThat(battle.getState().getPlayers().getFirst().getStreak()).isZero();
        assertThat(battle.getState().getPlayers().getFirst().getScore()).isEqualTo(1090);
        assertThat(battle.getState().getPlayers().get(1).getStreak()).isEqualTo(1);
    }
}
