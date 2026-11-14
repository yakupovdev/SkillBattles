package com.skillbattles.backend;

import com.fasterxml.jackson.databind.*;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.config.BattleProperties;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.exception.*;
import com.skillbattles.backend.processor.*;
import com.skillbattles.backend.scheduler.*;
import com.skillbattles.backend.service.*;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.*;
import org.springframework.context.annotation.*;
import org.springframework.context.event.EventListener;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.*;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.*;
import java.nio.file.*;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static com.skillbattles.backend.BattleFixtures.*;

@SpringBootTest(properties = {"app.jwt.secret=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=", "app.battle.scheduling.enabled=false",
        "app.battle.math.question-count=2", "app.battle.math.question-limit-seconds=10"})
@AutoConfigureMockMvc
@Import(BattlePostgresTest.TestConfig.class)
@Testcontainers(disabledWithoutDocker = true)
class BattlePostgresTest {
    @Container static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:17.12-alpine");
    @DynamicPropertySource static void database(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
    }

    @TestConfiguration
    static class TestConfig {
        @Bean @Primary MutableClock testClock() { return new MutableClock(); }
        @Bean @Primary TestPresence testPresence() { return new TestPresence(); }
        @Bean RecordedEvents recordedEvents() { return new RecordedEvents(); }
    }
    static class RecordedEvents {
        final List<BattleChangedEvent> values = new CopyOnWriteArrayList<>();
        @EventListener public void changed(BattleChangedEvent event) { values.add(event); }
    }

    @Autowired BattleProcessor processor;
    @MockitoSpyBean BattleService battles;
    @Autowired AuthProcessor auth;
    @Autowired QuestionService questions;
    @Autowired QuestionImportFileService files;
    @Autowired RatingService ratings;
    @Autowired StatisticsProcessor statistics;
    @Autowired BattleRecovery recovery;
    @Autowired MutableClock clock;
    @Autowired BattleProperties properties;
    @Autowired TestPresence presence;
    @Autowired RecordedEvents events;
    @Autowired JdbcTemplate jdbc;
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired org.springframework.transaction.PlatformTransactionManager transactionManager;

    @BeforeEach
    void setup() throws Exception {
        clock.set(START);
        presence.clear();
        events.values.clear();
        jdbc.execute("TRUNCATE TABLE battles, questions");
        questions.importQuestions(fixture(), false);
    }

    @Test
    void freezesContentAndShowsSameQuestionOrderAndDeadlinesToBothPlayers() throws Exception {
        Match match = create(BattleMode.RANKED, true);
        BattleDto saved = battles.lock(match.id());
        assertThat(saved.getState().getRounds()).hasSize(2);
        assertThat(saved.getState().getRounds().stream().map(round -> round.getQuestion().getId()).distinct().count()).isEqualTo(2);
        UUID originalId = saved.getState().getRounds().getFirst().getQuestion().getId();
        String key = jdbc.queryForObject("select external_key from questions where id = ?", String.class, originalId);
        var revised = fixture().stream().filter(item -> item.getExternalKey().equals(key)).findFirst().orElseThrow();
        revised.setContentVersion(2);
        revised.setPrompt("TEST ONLY: revised after battle creation");
        questions.importQuestions(List.of(revised), false);
        start(match);
        var first = processor.snapshot(match.id(), match.firstId());
        var second = processor.snapshot(match.id(), match.secondId());
        assertThat(first.getRound().getQuestion().getId()).isEqualTo(originalId);
        assertThat(json.<JsonNode>valueToTree(first.getRound().getQuestion())).isEqualTo(json.<JsonNode>valueToTree(second.getRound().getQuestion()));
        assertThat(first.getRound().getDeadline()).isEqualTo(second.getRound().getDeadline()).isEqualTo(START.plusSeconds(13));
        assertThat(first.getRound().getQuestion().getPrompt()).doesNotContain("revised after battle creation");
        assertThat(battles.lock(match.id()).getState().getRounds().getFirst().getQuestion().getExplanation()).isNotBlank();
    }

    @Test
    void advertisedDeadlineDoesNotChangeAfterPostgresRoundTripWithFractionalClock() {
        clock.set(START.plusNanos(123456789));
        Match match = create(BattleMode.RANKED, true);
        processor.ready(match.id(), match.firstId());
        var announced = processor.ready(match.id(), match.secondId()).getCountdownEndsAt();
        var reloaded = processor.snapshot(match.id(), match.firstId()).getCountdownEndsAt();
        assertThat(announced).isEqualTo(reloaded).isEqualTo(START.plusSeconds(3).plusNanos(123456000));
        clock.set(announced);
        processor.tick(match.id());
        assertThat(processor.snapshot(match.id(), match.firstId()).getRound().getDeadline())
                .isEqualTo(processor.snapshot(match.id(), match.secondId()).getRound().getDeadline());
    }

    @Test
    void httpContractValidatesTokensOwnershipReadinessAndDoesNotExposeCreation() throws Exception {
        Match match = create(BattleMode.RANKED, false);
        String access = match.first().getTokens().getAccessToken();
        mvc.perform(get("/api/v1/battles/" + match.id())).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/v1/battles/" + match.id()).header("Authorization", "Bearer " + match.first().getTokens().getRefreshToken())).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/v1/battles/" + match.id()).header("Authorization", "Bearer " + register().getTokens().getAccessToken()))
                .andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value("BATTLE_NOT_FOUND"));
        mvc.perform(post("/api/v1/battles/" + match.id() + "/readiness").header("Authorization", "Bearer " + access)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"ready\":true}"))
                .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("REALTIME_CONNECTION_REQUIRED"));
        mvc.perform(post("/api/v1/battles/" + match.id() + "/readiness").header("Authorization", "Bearer " + access)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"ready\":false}"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));
        mvc.perform(get("/api/v1/battles/" + match.id() + "/result").header("Authorization", "Bearer " + access))
                .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("BATTLE_NOT_FINISHED"));
        mvc.perform(post("/api/v1/battles").header("Authorization", "Bearer " + access)).andExpect(status().isNotFound());
        mvc.perform(get("/api/v1/battles/" + match.id() + "/review").header("Authorization", "Bearer " + access))
                .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("BATTLE_NOT_FINISHED"));
        mvc.perform(get("/v3/api-docs")).andExpect(status().isOk())
                .andExpect(jsonPath("$.paths['/api/v1/battles/{id}/answers'].post").exists())
                .andExpect(jsonPath("$.paths['/api/v1/battles'].post").doesNotExist());
    }

    @Test
    void answerReceiptIsIdempotentAndNeverLeaksCurrentRoundScores() throws Exception {
        Match match = create(BattleMode.RANKED, true);
        start(match);
        BattleDto saved = battles.lock(match.id());
        AnswerDto answer = answer(saved, true);
        clock.set(START.plusSeconds(4));
        String body = json.writeValueAsString(answer);
        var receipt = mvc.perform(post("/api/v1/battles/" + match.id() + "/answers")
                        .header("Authorization", "Bearer " + match.first().getTokens().getAccessToken()).contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk()).andExpect(jsonPath("$.accepted").value(true))
                .andExpect(jsonPath("$.acceptedAt").value("2026-11-14T12:00:04Z"))
                .andExpect(jsonPath("$.points").doesNotExist()).andExpect(jsonPath("$.correct").doesNotExist())
                .andReturn().getResponse().getContentAsString();
        mvc.perform(get("/api/v1/battles/" + match.id()).header("Authorization", "Bearer " + match.second().getTokens().getAccessToken()))
                .andExpect(status().isOk()).andExpect(jsonPath("$.round.mySelectedOptionId").isEmpty())
                .andExpect(jsonPath("$.round.reveal").isEmpty()).andExpect(jsonPath("$.players[0].score").value(0))
                .andExpect(jsonPath("$.round.question.correctOptionId").doesNotExist()).andExpect(jsonPath("$.round.question.explanation").doesNotExist());
        clock.set(START.plusSeconds(14));
        processor.tick(match.id());
        mvc.perform(post("/api/v1/battles/" + match.id() + "/answers")
                        .header("Authorization", "Bearer " + match.first().getTokens().getAccessToken()).contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk()).andExpect(content().json(receipt));
        answer.setOptionId(UUID.randomUUID());
        mvc.perform(post("/api/v1/battles/" + match.id() + "/answers")
                        .header("Authorization", "Bearer " + match.first().getTokens().getAccessToken()).contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(answer)))
                .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("IDEMPOTENCY_CONFLICT"));
    }

    @Test
    void concurrentAnswersAndConcurrentRetriesStoreEachSubmissionOnce() throws Exception {
        Match match = create(BattleMode.RANKED, true);
        start(match);
        clock.set(START.plusSeconds(4));
        BattleDto current = battles.lock(match.id());
        AnswerDto first = answer(current, true);
        var receipts = concurrent(() -> processor.answer(match.id(), match.firstId(), first, clock.instant()),
                () -> processor.answer(match.id(), match.firstId(), first, clock.instant()));
        assertThat(receipts.get(0)).isEqualTo(receipts.get(1));
        assertThat(round(battles.lock(match.id())).getAnswers()).hasSize(1);
        AnswerDto second = answer(current, false);
        concurrent(() -> processor.answer(match.id(), match.firstId(), first, clock.instant()),
                () -> processor.answer(match.id(), match.secondId(), second, clock.instant()));
        var stored = battles.lock(match.id());
        assertThat(stored.getPhase()).isEqualTo(BattlePhase.REVEAL);
        assertThat(round(stored).getAnswers()).hasSize(2);
        assertThat(stored.getState().getPlayers().getFirst().getScore()).isEqualTo(1090);
    }

    @Test
    void simultaneousDeadlineTicksAndSurrenderSettleEloOnceAndKeepOtherSubjectUnchanged() throws Exception {
        Match match = create(BattleMode.RANKED, true);
        start(match);
        playToFinalReveal(match, false);
        Instant finish = round(battles.lock(match.id())).getRevealEndsAt();
        clock.set(finish);
        concurrent(() -> { processor.tick(match.id()); return 1; }, () -> { processor.surrender(match.id(), match.firstId()); return 1; });
        var result = processor.result(match.id(), match.firstId());
        assertThat(result.getReason()).isEqualTo(CompletionReason.NORMAL);
        assertThat(result.getMyOutcome()).isEqualTo(Outcome.WIN);
        assertThat(result.getPlayers()).extracting(BattleResultPlayerDto::getRatingDelta).containsExactly(16, -16);
        assertRating(match.firstId(), Subject.MATH, 1016);
        assertRating(match.secondId(), Subject.MATH, 984);
        assertRating(match.firstId(), Subject.ENGLISH, 1000);
        var before = jdbc.queryForMap("select version, updated_at, result::text, settled_at from battles where id = ?", match.id());
        int eventCount = events.values.size();
        for (int i = 0; i < 3; i++) { processor.tick(match.id()); processor.surrender(match.id(), match.secondId()); }
        assertThat(jdbc.queryForMap("select version, updated_at, result::text, settled_at from battles where id = ?", match.id())).isEqualTo(before);
        assertThat(events.values).hasSize(eventCount);
        assertThat(statistics.getForUser(match.firstId()).getSubjects().getFirst().getRanked().getWins()).isEqualTo(1);
    }

    @Test
    void rollbackAfterRatingFlushLeavesBattleAndRatingsUnchangedAndPublishesNothing() {
        Match match = create(BattleMode.RANKED, true);
        start(match);
        events.values.clear();
        clock.set(START.plusSeconds(4));
        doThrow(new IllegalStateException("Test-only persistence failure")).when(battles).save(any());
        assertThatThrownBy(() -> processor.surrender(match.id(), match.firstId())).isInstanceOf(IllegalStateException.class);
        assertThat(battles.lock(match.id()).getPhase()).isEqualTo(BattlePhase.QUESTION);
        assertRating(match.firstId(), Subject.MATH, 1000);
        assertRating(match.secondId(), Subject.MATH, 1000);
        assertThat(events.values).isEmpty();
        doCallRealMethod().when(battles).save(any());
        processor.surrender(match.id(), match.firstId());
        assertRating(match.firstId(), Subject.MATH, 984);
        assertThat(events.values).hasSize(1);
    }

    @Test
    void terminalStateAndEventsAreNotVisibleUntilOuterTransactionCommits() {
        Match match = create(BattleMode.RANKED, true);
        start(match);
        events.values.clear();
        TransactionTemplate transaction = new TransactionTemplate(transactionManager);
        assertThatThrownBy(() -> transaction.execute(status -> {
            processor.surrender(match.id(), match.firstId());
            assertThat(events.values).isEmpty();
            throw new IllegalStateException("Test-only rollback");
        })).isInstanceOf(IllegalStateException.class);
        assertThat(events.values).isEmpty();
        assertThat(battles.lock(match.id()).getPhase()).isEqualTo(BattlePhase.QUESTION);
        assertRating(match.firstId(), Subject.MATH, 1000);
    }

    @Test
    void drawPrivateAndCancelledResultsMaintainSeparateStatistics() {
        Match draw = create(BattleMode.RANKED, true);
        start(draw);
        playToFinalReveal(draw, true);
        clock.set(round(battles.lock(draw.id())).getRevealEndsAt());
        processor.tick(draw.id());
        assertThat(processor.result(draw.id(), draw.firstId()).getMyOutcome()).isEqualTo(Outcome.DRAW);
        assertRating(draw.firstId(), Subject.MATH, 1000);
        clock.set(START.plusSeconds(100));
        Match privateMatch = createWith(draw.first(), draw.second(), BattleMode.PRIVATE, true);
        start(privateMatch);
        processor.surrender(privateMatch.id(), privateMatch.secondId());
        assertRating(draw.firstId(), Subject.MATH, 1000);
        assertThat(processor.result(privateMatch.id(), privateMatch.firstId()).getPlayers())
                .allSatisfy(player -> assertThat(player.getRatingDelta()).isZero());
        Match cancelled = createWith(draw.first(), draw.second(), BattleMode.RANKED, true);
        processor.surrender(cancelled.id(), cancelled.firstId());
        var stats = statistics.getForUser(draw.firstId()).getSubjects().getFirst();
        assertThat(stats.getRanked().getPlayed()).isEqualTo(1);
        assertThat(stats.getRanked().getDraws()).isEqualTo(1);
        assertThat(stats.getPrivateMatches().getPlayed()).isEqualTo(1);
        assertThat(stats.getPrivateMatches().getWins()).isEqualTo(1);
    }

    @Test
    void restartCancelsNonterminalBattlesAndKeepsTerminalResults() {
        Match completed = create(BattleMode.RANKED, true);
        processor.surrender(completed.id(), completed.firstId());
        var frozen = jdbc.queryForMap("select version, result::text from battles where id = ?", completed.id());
        Match active = create(BattleMode.RANKED, true);
        start(active);
        recovery.recover();
        assertThat(processor.result(active.id(), active.firstId()).getReason()).isEqualTo(CompletionReason.SERVER_INTERRUPTION);
        assertRating(active.firstId(), Subject.MATH, 1000);
        recovery.recover();
        assertThat(jdbc.queryForMap("select version, result::text from battles where id = ?", completed.id())).isEqualTo(frozen);
    }

    @Test
    void contentShortageAndActiveParticipantConflictDoNotCreatePartialBattles() throws Exception {
        jdbc.execute("TRUNCATE questions");
        AuthDto first = register(), second = register();
        assertThatThrownBy(() -> createWith(first, second, BattleMode.RANKED, true)).isInstanceOfSatisfying(ConflictException.class,
                ex -> assertThat(ex.getCode()).isEqualTo("CONTENT_UNAVAILABLE"));
        assertThat(jdbc.queryForObject("select count(*) from battles", Integer.class)).isZero();
        questions.importQuestions(fixture(), false);
        createWith(first, second, BattleMode.RANKED, true);
        assertThatThrownBy(() -> createWith(second, register(), BattleMode.PRIVATE, true)).isInstanceOfSatisfying(ConflictException.class,
                ex -> assertThat(ex.getCode()).isEqualTo("ACTIVITY_CONFLICT"));
        assertThat(jdbc.queryForObject("select count(*) from battles", Integer.class)).isEqualTo(1);
    }

    @Test
    void deadlineRacingAnswerNeverAcceptsAtEqualityOrAwardsTimeoutPoints() throws Exception {
        Match match = create(BattleMode.RANKED, true);
        start(match);
        BattleDto before = battles.lock(match.id());
        AnswerDto answer = answer(before, true);
        clock.set(round(before).getDeadline());
        var outcome = concurrent(() -> {
            try { processor.answer(match.id(), match.firstId(), answer, clock.instant()); return "accepted"; }
            catch (BusinessException error) { return error.getCode(); }
        }, () -> { processor.tick(match.id()); return "tick"; });
        assertThat(outcome).containsExactlyInAnyOrder("ROUND_CLOSED", "tick");
        var saved = battles.lock(match.id());
        assertThat(saved.getPhase()).isEqualTo(BattlePhase.REVEAL);
        assertThat(round(saved).getAnswers()).hasSize(2).allSatisfy(item -> {
            assertThat(item.isTimedOut()).isTrue();
            assertThat(item.getPoints()).isZero();
        });
        assertThat(saved.getState().getPlayers()).allSatisfy(player -> assertThat(player.getScore()).isZero());
    }

    @Test
    void schedulerPollIsIdempotentAndDisconnectSessionReplacementDoesNotMarkNewSessionOffline() {
        Match match = create(BattleMode.RANKED, true);
        start(match);
        var scheduler = new BattleScheduler(battles, processor, recovery);
        var before = jdbc.queryForMap("select version, updated_at from battles where id = ?", match.id());
        scheduler.poll(); scheduler.poll();
        assertThat(jdbc.queryForMap("select version, updated_at from battles where id = ?", match.id())).isEqualTo(before);
        presence.connect(match.firstId(), clock.instant());
        scheduler.poll();
        assertThat(processor.snapshot(match.id(), match.firstId()).getPlayers().getFirst().isConnected()).isTrue();
        presence.disconnect(match.firstId());
        clock.set(START.plusSeconds(4));
        scheduler.poll();
        assertThat(processor.snapshot(match.id(), match.firstId()).getPlayers().getFirst().getReconnectDeadline()).isEqualTo(START.plusSeconds(34));
    }

    @Test
    void questionSelectionCombinesBothPlayersAndBothModesBeforeChoosingOldestFallback() {
        UUID a = register().getUser().getId(), b = register().getUser().getId();
        UUID other = register().getUser().getId();
        UUID q1 = questionId("test-math-1"), q2 = questionId("test-math-2"), q3 = questionId("test-math-3");
        history(a, other, Subject.MATH, BattleMode.RANKED, START.minusSeconds(30), List.of(q1), 1);
        history(other, b, Subject.MATH, BattleMode.PRIVATE, START.minusSeconds(10), List.of(q2), 1);
        for (BattleMode mode : BattleMode.values()) {
            UUID id = processor.create(new CreateBattleDto(a, b, Subject.MATH, mode));
            assertThat(battles.lock(id).getState().getRounds()).extracting(round -> round.getQuestion().getId()).containsExactly(q3, q1);
            processor.interrupt(id);
        }
    }

    @Test
    void unshownRoundsAndBattlesThatNeverStartedDoNotCountAsSeen() {
        UUID a = register().getUser().getId(), b = register().getUser().getId(), other = register().getUser().getId();
        UUID q1 = questionId("test-math-1"), q2 = questionId("test-math-2"), q3 = questionId("test-math-3");
        history(a, other, Subject.MATH, BattleMode.RANKED, START.minusSeconds(20), List.of(q1, q2), 1);
        history(a, other, Subject.MATH, BattleMode.PRIVATE, START.minusSeconds(1), List.of(q3), 0);
        assertThat(battles.recentQuestionShows(a, Subject.MATH, 1)).extracting(QuestionSeenDto::getQuestionId).containsExactly(q1);
        UUID id = processor.create(new CreateBattleDto(a, b, Subject.MATH, BattleMode.RANKED));
        assertThat(battles.lock(id).getState().getRounds()).extracting(round -> round.getQuestion().getId()).containsExactlyInAnyOrder(q2, q3);
    }

    @Test
    void historyWindowCountsStartedBattlesPerSubjectRatherThanRoundsOrCreationOrder() {
        UUID a = register().getUser().getId(), b = register().getUser().getId(), other = register().getUser().getId();
        UUID q1 = questionId("test-math-1"), q2 = questionId("test-math-2"), q3 = questionId("test-math-3");
        // Insert in reverse start order; all fixture createdAt values are identical.
        for (int i = 1; i <= 6; i++) {
            history(a, other, Subject.MATH, BattleMode.RANKED, START.minusSeconds(i * 100L), List.of(i == 6 ? q1 : q2), 1);
        }
        for (int i = 1; i <= 6; i++) {
            history(a, other, Subject.ENGLISH, BattleMode.PRIVATE, START.minusSeconds(i), List.of(questionId("test-english-1")), 1);
        }
        assertThat(properties.getQuestionHistoryBattles()).isEqualTo(5);
        assertThat(battles.recentQuestionShows(a, Subject.MATH, 5)).hasSize(5)
                .extracting(QuestionSeenDto::getQuestionId).containsOnly(q2);
        UUID id = processor.create(new CreateBattleDto(a, b, Subject.MATH, BattleMode.RANKED));
        assertThat(battles.lock(id).getState().getRounds()).extracting(round -> round.getQuestion().getId()).containsExactlyInAnyOrder(q1, q3);
        assertThat(battles.recentQuestionShows(a, Subject.ENGLISH, 5)).hasSize(5)
                .extracting(QuestionSeenDto::getQuestionId).containsOnly(questionId("test-english-1"));
    }

    @Test
    void configuredWindowAndBothSnapshotTimestampFormatsAreHonoured() {
        UUID a = register().getUser().getId(), b = register().getUser().getId(), other = register().getUser().getId();
        UUID q1 = questionId("test-math-1"), q2 = questionId("test-math-2"), q3 = questionId("test-math-3");
        history(a, other, Subject.MATH, BattleMode.RANKED, START.minusSeconds(30), List.of(q1), 1);
        Instant latest = START.minusSeconds(10).plusNanos(123456000);
        UUID recent = history(a, other, Subject.MATH, BattleMode.PRIVATE, latest, List.of(q2, q3), 2);
        jdbc.update("update battles set state = jsonb_set(state, '{rounds,0,startedAt}', to_jsonb(CAST(? AS text))) where id = ?", latest.toString(), recent);
        var shows = battles.recentQuestionShows(a, Subject.MATH, 1);
        assertThat(shows).extracting(QuestionSeenDto::getQuestionId).containsExactlyInAnyOrder(q2, q3);
        assertThat(shows.stream().filter(show -> show.getQuestionId().equals(q2)).findFirst().orElseThrow().getShownAt()).isEqualTo(latest);
        try {
            properties.setQuestionHistoryBattles(1);
            clearInvocations(battles);
            UUID id = processor.create(new CreateBattleDto(a, b, Subject.MATH, BattleMode.RANKED));
            assertThat(battles.lock(id).getState().getRounds()).extracting(round -> round.getQuestion().getId()).containsExactly(q1, q2);
            verify(battles).recentQuestionShows(a, Subject.MATH, 1);
            verify(battles).recentQuestionShows(b, Subject.MATH, 1);
        } finally { properties.setQuestionHistoryBattles(5); }
    }

    @Test
    void fallbackUsesLatestShowToEitherPlayerAndOldestQuestionFirst() {
        UUID a = register().getUser().getId(), b = register().getUser().getId(), other = register().getUser().getId();
        UUID q1 = questionId("test-math-1"), q2 = questionId("test-math-2"), q3 = questionId("test-math-3");
        history(a, other, Subject.MATH, BattleMode.RANKED, START.minusSeconds(40), List.of(q1), 1);
        history(a, other, Subject.MATH, BattleMode.PRIVATE, START.minusSeconds(30), List.of(q2), 1);
        history(a, other, Subject.MATH, BattleMode.RANKED, START.minusSeconds(20), List.of(q3), 1);
        history(other, b, Subject.MATH, BattleMode.PRIVATE, START.minusSeconds(10), List.of(q1), 1);
        UUID id = processor.create(new CreateBattleDto(a, b, Subject.MATH, BattleMode.RANKED));
        assertThat(battles.lock(id).getState().getRounds()).extracting(round -> round.getQuestion().getId()).containsExactly(q2, q3);
    }

    @Test
    void revisionsShareHistoryEvenAfterOldRevisionWasSoftDeleted() throws Exception {
        UUID a = register().getUser().getId(), b = register().getUser().getId(), other = register().getUser().getId();
        UUID old = questionId("test-math-1"), q2 = questionId("test-math-2"), q3 = questionId("test-math-3");
        history(a, other, Subject.MATH, BattleMode.RANKED, START.minusSeconds(20), List.of(old), 1);
        var revision = fixture().stream().filter(item -> item.getExternalKey().equals("test-math-1")).findFirst().orElseThrow();
        revision.setContentVersion(2);
        questions.importQuestions(List.of(revision), false);
        jdbc.update("update questions set deleted = true where id = ?", old);
        UUID current = questionId("test-math-1");
        assertThat(current).isNotEqualTo(old);
        var seen = battles.recentQuestionShows(a, Subject.MATH, 5);
        assertThat(questions.selectForBattle(new QuestionSelectionDto(Subject.MATH, 2, seen)))
                .extracting(FrozenQuestionDto::getId).containsExactlyInAnyOrder(q2, q3);
        assertThat(questions.selectForBattle(new QuestionSelectionDto(Subject.MATH, 3, seen)))
                .extracting(FrozenQuestionDto::getId).containsExactlyInAnyOrder(current, q2, q3);
        jdbc.update("update questions set active = false where id in (?,?)", q2, q3);
        assertThat(questions.selectForBattle(new QuestionSelectionDto(Subject.MATH, 1, seen)))
                .extracting(FrozenQuestionDto::getId).containsExactly(current);
        assertThatThrownBy(() -> questions.selectForBattle(new QuestionSelectionDto(Subject.MATH, 2, seen)))
                .isInstanceOfSatisfying(ConflictException.class, error -> assertThat(error.getCode()).isEqualTo("CONTENT_UNAVAILABLE"));
    }

    @Test
    void smallBankReusesSeenQuestionsAndOnlyRealContentShortageBlocksCreation() {
        UUID a = register().getUser().getId(), b = register().getUser().getId(), other = register().getUser().getId();
        UUID q1 = questionId("test-math-1"), q2 = questionId("test-math-2");
        jdbc.update("update questions set active = false where external_key = 'test-math-3'");
        history(a, other, Subject.MATH, BattleMode.RANKED, START.minusSeconds(20), List.of(q1, q2), 2);
        history(other, b, Subject.MATH, BattleMode.PRIVATE, START.minusSeconds(10), List.of(q2, q1), 2);
        UUID id = processor.create(new CreateBattleDto(a, b, Subject.MATH, BattleMode.PRIVATE));
        assertThat(battles.lock(id).getState().getRounds()).extracting(round -> round.getQuestion().getId()).containsExactly(q2, q1);
        processor.interrupt(id);
        jdbc.update("update questions set active = false where id = ?", q1);
        int before = jdbc.queryForObject("select count(*) from battles", Integer.class);
        assertThatThrownBy(() -> processor.create(new CreateBattleDto(a, b, Subject.MATH, BattleMode.RANKED)))
                .isInstanceOfSatisfying(ConflictException.class, error -> assertThat(error.getCode()).isEqualTo("CONTENT_UNAVAILABLE"));
        assertThat(jdbc.queryForObject("select count(*) from battles", Integer.class)).isEqualTo(before);
    }

    private UUID history(UUID first, UUID second, Subject subject, BattleMode mode, Instant at, List<UUID> ids, int shown) {
        BattleDto battle = waiting(ids.size(), mode, 1000, 1000);
        battle.setSubject(subject);
        battle.getState().getPlayers().get(0).setId(first);
        battle.getState().getPlayers().get(1).setId(second);
        for (int i = 0; i < ids.size(); i++) {
            var round = battle.getState().getRounds().get(i);
            round.getQuestion().setId(ids.get(i));
            round.getQuestion().setSubject(subject);
            if (i < shown) { round.setStartedAt(at.plusSeconds(i)); round.setDeadline(at.plusSeconds(i + 10)); }
        }
        battle.getState().setCurrentRoundIndex(shown - 1);
        new BattleEngineImpl().interrupt(battle, at.plusSeconds(100));
        return battles.create(battle).getId();
    }

    private UUID questionId(String key) {
        return jdbc.queryForObject("select id from questions where external_key = ? and active = true and deleted = false", UUID.class, key);
    }

    private Match create(BattleMode mode, boolean connected) { return createWith(register(), register(), mode, connected); }
    private Match createWith(AuthDto first, AuthDto second, BattleMode mode, boolean connected) {
        if (connected) {
            presence.connect(first.getUser().getId(), clock.instant());
            presence.connect(second.getUser().getId(), clock.instant());
        }
        UUID id = processor.create(new CreateBattleDto(first.getUser().getId(), second.getUser().getId(), Subject.MATH, mode));
        return new Match(id, first, second);
    }
    private void start(Match match) {
        processor.ready(match.id(), match.firstId());
        processor.ready(match.id(), match.secondId());
        clock.set(clock.instant().plusSeconds(3));
        processor.tick(match.id());
    }
    private void playToFinalReveal(Match match, boolean tie) {
        for (int i = 0; i < 2; i++) {
            BattleDto current = battles.lock(match.id());
            clock.set(round(current).getStartedAt().plusSeconds(1));
            processor.answer(match.id(), match.firstId(), answer(current, true), clock.instant());
            processor.answer(match.id(), match.secondId(), answer(current, tie), clock.instant());
            if (i == 0) {
                clock.set(round(battles.lock(match.id())).getRevealEndsAt());
                processor.tick(match.id());
            }
        }
    }
    private List<QuestionImportDto> fixture() throws Exception {
        return files.read(Path.of(Objects.requireNonNull(getClass().getResource("/fixtures/stage2-questions-test-only.json")).toURI()));
    }
    private AuthDto register() {
        RegisterDto command = new RegisterDto();
        String suffix = UUID.randomUUID().toString().replace("-", "").substring(0, 12);
        command.setEmail(suffix + "@example.com"); command.setNickname("Test_" + suffix); command.setPassword("ExamplePass123!");
        return auth.register(command);
    }
    private void assertRating(UUID userId, Subject subject, int expected) {
        assertThat(ratings.getByUserId(userId).stream().filter(item -> item.getSubject() == subject).findFirst().orElseThrow().getRating()).isEqualTo(expected);
    }
    private <T> List<T> concurrent(Callable<T> first, Callable<T> second) throws Exception {
        CountDownLatch ready = new CountDownLatch(2), start = new CountDownLatch(1);
        try (var executor = Executors.newFixedThreadPool(2)) {
            var a = executor.submit(() -> { ready.countDown(); if (!start.await(10, TimeUnit.SECONDS)) throw new IllegalStateException(); return first.call(); });
            var b = executor.submit(() -> { ready.countDown(); if (!start.await(10, TimeUnit.SECONDS)) throw new IllegalStateException(); return second.call(); });
            assertThat(ready.await(10, TimeUnit.SECONDS)).isTrue(); start.countDown();
            return List.of(a.get(20, TimeUnit.SECONDS), b.get(20, TimeUnit.SECONDS));
        }
    }
    private record Match(UUID id, AuthDto first, AuthDto second) {
        UUID firstId() { return first.getUser().getId(); }
        UUID secondId() { return second.getUser().getId(); }
    }
}
