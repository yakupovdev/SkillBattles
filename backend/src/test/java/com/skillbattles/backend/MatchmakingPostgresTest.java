package com.skillbattles.backend;

import com.fasterxml.jackson.databind.*;
import com.skillbattles.backend.config.*;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.exception.*;
import com.skillbattles.backend.processor.*;
import com.skillbattles.backend.scheduler.BattleRecovery;
import com.skillbattles.backend.service.*;
import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.*;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.context.annotation.*;
import org.springframework.context.event.EventListener;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.*;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.web.servlet.*;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.*;
import java.net.URI;
import java.net.http.HttpClient;
import java.nio.file.*;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import static org.assertj.core.api.Assertions.*;
import static org.awaitility.Awaitility.await;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doAnswer;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static com.skillbattles.backend.BattleFixtures.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {
        "app.jwt.secret=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=", "app.battle.scheduling.enabled=false",
        "app.matchmaking.scheduling.enabled=false", "app.realtime.monitor-ms=3600000",
        "app.battle.math.question-count=2", "app.battle.math.question-limit-seconds=10"})
@AutoConfigureMockMvc
@Import(MatchmakingPostgresTest.TestConfig.class)
@Testcontainers(disabledWithoutDocker = true)
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
class MatchmakingPostgresTest {
    @Container static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:17.12-alpine");
    @DynamicPropertySource static void database(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
    }
    @TestConfiguration static class TestConfig {
        @Bean @Primary MutableClock testClock() { return new MutableClock(); }
        @Bean RecordedEvents recordedEvents() { return new RecordedEvents(); }
    }
    static class RecordedEvents {
        final List<ActivityChangedEvent> values = new CopyOnWriteArrayList<>();
        @EventListener public void changed(ActivityChangedEvent event) { values.add(event); }
    }
    @Autowired MatchmakingProcessor matchmaking;
    @Autowired MatchmakingRegistryService registry;
    @Autowired BattleProcessor processor;
    @MockitoSpyBean BattleService battles;
    @Autowired AuthProcessor auth;
    @Autowired UserService users;
    @Autowired RatingService ratings;
    @Autowired RatingProcessor ratingProcessor;
    @Autowired UsageProcessor usage;
    @Autowired SubscriptionService subscriptions;
    @Autowired BattleProperties battleProperties;
    @Autowired DisciplineService disciplines;
    @Autowired MatchmakingProperties properties;
    @Autowired QuestionService questions;
    @Autowired QuestionImportFileService files;
    @Autowired DuelInvitationReconciler invitations;
    @Autowired MutableClock clock;
    @Autowired JdbcTemplate jdbc;
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired PlatformTransactionManager transactions;
    @Autowired org.springframework.context.ApplicationEventPublisher publisher;
    @Autowired RecordedEvents events;
    @Autowired RealtimeSessionService sessions;
    @Autowired BattleRecovery recovery;
    @LocalServerPort int port;
    private final HttpClient http = HttpClient.newHttpClient();
    private final List<NativeStompClient> clients = new ArrayList<>();

    @BeforeEach void setup() throws Exception {
        uniformTiming(jdbc, 10);
        clock.set(START);
        registry.transact(state -> { state.getEntries().clear(); state.getDuels().clear(); state.getActivities().clear(); return null; });
        jdbc.execute("TRUNCATE question_reports,ranked_usage, battles, questions");
        questions.importQuestions(files.read(Path.of(Objects.requireNonNull(getClass().getResource("/fixtures/stage2-questions-test-only.json")).toURI())), false);
        events.values.clear();
    }
    @AfterEach void cleanup() {
        for (var client : clients) client.close();
        await().atMost(Duration.ofSeconds(5)).until(() -> !sessions.hasSubscribers());
        http.close();
    }

    @Test void fastRankedMatchCreatesOneFrozenBattleAndBothActivitiesPointToIt() {
        var a = register(); var b = register();
        rating(a, "SAT_RW", 1900); rating(b, "SAT_RW", 100);
        rating(b, "SAT_MATH", 1050);
        var first = matchmaking.search(id(a), "SAT_MATH");
        var second = matchmaking.search(id(b), "SAT_MATH");
        assertThat(first.getStatus()).isEqualTo(QueueStatus.SEARCHING);
        assertThat(second.getStatus()).isEqualTo(QueueStatus.MATCHED);
        assertThat(matchmaking.entry(id(a), first.getId()).getBattleId()).isEqualTo(second.getBattleId());
        assertThat(battleCount()).isEqualTo(1);
        var battle = battles.lock(second.getBattleId());
        assertThat(battle.getMode()).isEqualTo(BattleMode.RANKED);
        assertThat(battle.getPhase()).isEqualTo(BattlePhase.WAITING_READY);
        assertThat(battle.getState().getPlayers()).extracting(BattlePlayerDto::getId, BattlePlayerDto::getRating)
                .containsExactlyInAnyOrder(tuple(id(a), 1000), tuple(id(b), 1050));
        assertThat(battle.getState().getRounds()).hasSize(5);
        for (var user : List.of(a, b)) {
            var activity = matchmaking.activity(id(user));
            assertThat(activity.getType()).isEqualTo(ActivityType.BATTLE);
            assertThat(activity.getResourceId()).isEqualTo(second.getBattleId()).isEqualTo(activity.getBattleId());
        }
        assertCode(() -> matchmaking.cancelEntry(id(a), first.getId()), "MATCH_ALREADY_FOUND");
        assertCode(() -> matchmaking.search(id(a), "SAT_RW"), "ACTIVITY_CONFLICT");
    }

    @Test void subjectsNeverCrossAndOldestEligibleOpponentWins() {
        var english = register(); var oldest = register(); var newer = register(); var arriving = register();
        matchmaking.search(id(english), "SAT_RW");
        rating(oldest, "SAT_MATH", 900); rating(newer, "SAT_MATH", 1100);
        var first = matchmaking.search(id(oldest), "SAT_MATH");
        clock.set(START.plusSeconds(1)); var second = matchmaking.search(id(newer), "SAT_MATH");
        clock.set(START.plusSeconds(2)); var matched = matchmaking.search(id(arriving), "SAT_MATH");
        assertThat(matchmaking.entry(id(oldest), first.getId()).getBattleId()).isEqualTo(matched.getBattleId());
        assertThat(matchmaking.entry(id(newer), second.getId()).getStatus()).isEqualTo(QueueStatus.SEARCHING);
        assertThat(matchmaking.activity(id(english)).getType()).isEqualTo(ActivityType.QUEUE);
        assertThat(battleCount()).isEqualTo(1);
    }

    @ParameterizedTest @CsvSource({"14999,100", "15000,200", "29999,200", "30000,400", "89999,400"})
    void windowsChangeAtExactServerBoundariesAndStableReadsDoNotVersion(long millis, int expected) {
        var user = register(); var original = matchmaking.search(id(user), "SAT_MATH");
        clock.set(START.plusMillis(millis));
        var current = matchmaking.entry(id(user), original.getId());
        assertThat(current.getRatingWindow()).isEqualTo(expected);
        assertThat(matchmaking.entry(id(user), original.getId()).getVersion()).isEqualTo(current.getVersion());
    }

    @Test void ratingGapMustFitBothCurrentWindowsAndNeverExceedsFourHundred() {
        var a = register(); var b = register(); var far = register();
        rating(b, "SAT_MATH", 1300); rating(far, "SAT_MATH", 2000);
        var first = matchmaking.search(id(a), "SAT_MATH");
        clock.set(START.plusSeconds(30)); var second = matchmaking.search(id(b), "SAT_MATH");
        matchmaking.search(id(far), "SAT_MATH");
        assertThat(second.getStatus()).isEqualTo(QueueStatus.SEARCHING);
        clock.set(START.plusSeconds(45)); matchmaking.poll(); assertThat(battleCount()).isZero();
        clock.set(START.plusSeconds(60)); matchmaking.poll();
        assertThat(matchmaking.entry(id(a), first.getId()).getBattleId()).isEqualTo(matchmaking.entry(id(b), second.getId()).getBattleId()).isNotNull();
        assertThat(matchmaking.activity(id(far)).getType()).isEqualTo(ActivityType.QUEUE);
        assertThat(battleCount()).isEqualTo(1);
    }

    @Test void searchExpiryAndCancelAreIdempotentAndReleaseAccount() {
        var a = register(); var first = matchmaking.search(id(a), "SAT_MATH");
        clock.set(START.plusSeconds(90));
        assertThat(matchmaking.entry(id(a), first.getId()).getStatus()).isEqualTo(QueueStatus.EXPIRED);
        matchmaking.cancelEntry(id(a), first.getId()); matchmaking.cancelEntry(id(a), first.getId());
        assertThat(matchmaking.activity(id(a)).getType()).isEqualTo(ActivityType.NONE);
        var room = matchmaking.createDuel(id(a), "SAT_RW");
        assertCode(() -> matchmaking.search(id(a), "SAT_MATH"), "ACTIVITY_CONFLICT");
        matchmaking.cancelDuel(id(a), room.getId()); matchmaking.cancelDuel(id(a), room.getId());
        var next = matchmaking.search(id(a), "SAT_MATH");
        matchmaking.cancelEntry(id(a), next.getId());
        assertThat(matchmaking.entry(id(a), next.getId()).getStatus()).isEqualTo(QueueStatus.CANCELLED);
        assertThat(matchmaking.activity(id(a)).getType()).isEqualTo(ActivityType.NONE);
    }

    @Test void duplicateSearchAndQueueVersusRoomCannotReserveTwoActivities() throws Exception {
        var a = register();
        var duplicate = race(() -> matchmaking.search(id(a), "SAT_MATH"), () -> matchmaking.search(id(a), "SAT_RW"));
        assertThat(duplicate.stream().filter(QueueEntryDto.class::isInstance)).hasSize(1);
        assertThat(duplicate).contains("ACTIVITY_CONFLICT");
        assertThat(battleCount()).isZero();
        var b = register();
        var competing = race(() -> matchmaking.search(id(b), "SAT_RW"), () -> matchmaking.createDuel(id(b), "SAT_MATH"));
        assertThat(competing).contains("ACTIVITY_CONFLICT");
        assertThat(competing.stream().filter(value -> value instanceof QueueEntryDto || value instanceof DuelDto)).hasSize(1);
    }

    @Test void matchVersusCancelCreatesEitherOneBattleOrNoBattleWithoutOrphans() throws Exception {
        var a = register(); var b = register(); var first = matchmaking.search(id(a), "SAT_MATH");
        var results = race(() -> { matchmaking.cancelEntry(id(a), first.getId()); return "CANCELLED"; }, () -> matchmaking.search(id(b), "SAT_MATH"));
        var current = matchmaking.entry(id(a), first.getId());
        if (current.getStatus() == QueueStatus.MATCHED) {
            assertThat(results).contains("MATCH_ALREADY_FOUND"); assertThat(battleCount()).isEqualTo(1);
            assertThat(matchmaking.activity(id(a)).getBattleId()).isEqualTo(matchmaking.activity(id(b)).getBattleId()).isEqualTo(current.getBattleId());
        } else {
            assertThat(current.getStatus()).isEqualTo(QueueStatus.CANCELLED); assertThat(results).contains("CANCELLED");
            assertThat(battleCount()).isZero(); assertThat(matchmaking.activity(id(a)).getType()).isEqualTo(ActivityType.NONE);
        }
    }

    @Test void matchVersusExpiryAtDeadlineCannotMatchExpiredPlayer() throws Exception {
        var a = register(); var b = register(); var first = matchmaking.search(id(a), "SAT_MATH");
        clock.set(START.plusSeconds(90));
        race(() -> { matchmaking.poll(); return "POLL"; }, () -> matchmaking.search(id(b), "SAT_MATH"));
        assertThat(matchmaking.entry(id(a), first.getId()).getStatus()).isEqualTo(QueueStatus.EXPIRED);
        assertThat(matchmaking.activity(id(a)).getType()).isEqualTo(ActivityType.NONE);
        assertThat(matchmaking.activity(id(b)).getType()).isEqualTo(ActivityType.QUEUE);
        assertThat(battleCount()).isZero();
    }

    @Test void privateCodeNormalizesAndDoesNotReuseMatchedRoomOrAllowSelfOrRepeatedJoin() {
        var host = register(); var guest = register(); var outsider = register();
        var room = matchmaking.createDuel(id(host), "SAT_RW");
        assertThat(room.getCode()).matches("[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{6}");
        assertThat(room.getExpiresAt()).isEqualTo(START.plusSeconds(600));
        assertCode(() -> matchmaking.join(id(host), room.getCode()), "SELF_JOIN_NOT_ALLOWED");
        assertCode(() -> matchmaking.join(id(guest), room.getCode().equals("AAAAAA") ? "BBBBBB" : "AAAAAA"), "DUEL_NOT_FOUND");
        var joined = matchmaking.join(id(guest), "  " + room.getCode().toLowerCase(Locale.ROOT) + "  ");
        assertThat(joined.getStatus()).isEqualTo(DuelStatus.MATCHED);
        assertThat(battles.lock(joined.getBattleId()).getMode()).isEqualTo(BattleMode.PRIVATE);
        assertCode(() -> matchmaking.join(id(guest), room.getCode()), "DUEL_NOT_JOINABLE");
        assertCode(() -> matchmaking.join(id(outsider), room.getCode()), "DUEL_NOT_JOINABLE");
        assertCode(() -> matchmaking.cancelDuel(id(host), room.getId()), "MATCH_ALREADY_FOUND");
        processor.surrender(joined.getBattleId(), id(host));
        assertCode(() -> matchmaking.join(id(guest), room.getCode()), "DUEL_NOT_JOINABLE");
        assertThat(battleCount()).isEqualTo(1);
        assertThat(matchmaking.createDuel(id(host), "SAT_MATH").getCode()).isNotEqualTo(room.getCode());
    }

    @ParameterizedTest @ValueSource(booleans = {false, true})
    void twoGuestsAndRepeatGuestRaceCreateExactlyOnePrivateBattle(boolean sameGuest) throws Exception {
        var host = register(); var a = register(); var b = sameGuest ? a : register();
        var room = matchmaking.createDuel(id(host), "SAT_MATH");
        var joined = race(() -> matchmaking.join(id(a), room.getCode()), () -> matchmaking.join(id(b), room.getCode()));
        assertThat(joined.stream().filter(DuelDto.class::isInstance)).hasSize(1);
        assertThat(joined).contains("DUEL_NOT_JOINABLE"); assertThat(battleCount()).isEqualTo(1);
        var matched = matchmaking.duel(id(host), room.getId());
        var loser = matched.getGuest().getId().equals(id(a)) ? b : a;
        if (!sameGuest) assertThat(matchmaking.activity(id(loser)).getType()).isEqualTo(ActivityType.NONE);
        assertCode(() -> matchmaking.join(matched.getGuest().getId(), room.getCode()), "DUEL_NOT_JOINABLE");
    }

    @Test void joinVersusHostCancelHasOneConsistentWinner() throws Exception {
        var host = register(); var guest = register(); var room = matchmaking.createDuel(id(host), "SAT_MATH");
        var results = race(() -> matchmaking.join(id(guest), room.getCode()), () -> { matchmaking.cancelDuel(id(host), room.getId()); return "CANCELLED"; });
        var current = matchmaking.duel(id(host), room.getId());
        if (current.getStatus() == DuelStatus.MATCHED) {
            assertThat(results).contains("MATCH_ALREADY_FOUND"); assertThat(battleCount()).isEqualTo(1);
        } else {
            assertThat(current.getStatus()).isEqualTo(DuelStatus.CANCELLED);
            assertThat(results).contains("DUEL_NOT_JOINABLE", "CANCELLED"); assertThat(battleCount()).isZero();
            assertThat(matchmaking.activity(id(host)).getType()).isEqualTo(ActivityType.NONE);
            assertThat(matchmaking.activity(id(guest)).getType()).isEqualTo(ActivityType.NONE);
        }
    }

    @Test void expiryCancelledCodeAndBusyGuestHaveDistinctErrorsAndNoReservationLeak() {
        var host = register(); var guest = register();
        var room = matchmaking.createDuel(id(host), "SAT_MATH");
        var queue = matchmaking.search(id(guest), "SAT_RW");
        assertCode(() -> matchmaking.join(id(guest), room.getCode()), "ACTIVITY_CONFLICT");
        assertThat(matchmaking.duel(id(host), room.getId()).getGuest()).isNull();
        matchmaking.cancelEntry(id(guest), queue.getId());
        clock.set(START.plusSeconds(600));
        assertCode(() -> matchmaking.join(id(guest), room.getCode()), "DUEL_EXPIRED");
        assertThat(matchmaking.duel(id(host), room.getId()).getStatus()).isEqualTo(DuelStatus.EXPIRED);
        assertThat(matchmaking.activity(id(host)).getType()).isEqualTo(ActivityType.NONE);
        var cancelled = matchmaking.createDuel(id(host), "SAT_MATH");
        matchmaking.cancelDuel(id(host), cancelled.getId());
        assertCode(() -> matchmaking.join(id(guest), cancelled.getCode()), "DUEL_NOT_JOINABLE");
        assertThat(matchmaking.activity(id(guest)).getType()).isEqualTo(ActivityType.NONE);
        assertThat(battleCount()).isZero();
    }

    @Test void missingContentRejectsCreationAndJoinAndInvalidatesQueueSafely() {
        var host = register(); var guest = register(); var queued = register();
        var room = matchmaking.createDuel(id(host), "SAT_MATH");
        var entry = matchmaking.search(id(queued), "SAT_RW");
        jdbc.execute("UPDATE questions SET active=false");
        assertCode(() -> matchmaking.search(id(guest), "SAT_MATH"), "CONTENT_UNAVAILABLE");
        assertCode(() -> matchmaking.createDuel(id(guest), "SAT_MATH"), "CONTENT_UNAVAILABLE");
        assertCode(() -> matchmaking.join(id(guest), room.getCode()), "CONTENT_UNAVAILABLE");
        assertThat(matchmaking.activity(id(guest)).getType()).isEqualTo(ActivityType.NONE);
        assertThat(matchmaking.duel(id(host), room.getId()).getStatus()).isEqualTo(DuelStatus.WAITING);
        assertThat(matchmaking.entry(id(queued), entry.getId()).getStatus()).isEqualTo(QueueStatus.CANCELLED);
        assertThat(matchmaking.activity(id(queued)).getType()).isEqualTo(ActivityType.NONE);
        assertThat(battleCount()).isZero();
    }

    @Test void internalBattleCreationCannotBypassWaitingAccountActivity() {
        var a = register(); var b = register(); var queue = matchmaking.search(id(a), "SAT_MATH");
        assertCode(() -> processor.create(new CreateBattleDto(id(a), id(b), "SAT_MATH", BattleMode.RANKED)), "ACTIVITY_CONFLICT");
        matchmaking.cancelEntry(id(a), queue.getId()); matchmaking.createDuel(id(a), "SAT_MATH");
        assertCode(() -> processor.create(new CreateBattleDto(id(a), id(b), "SAT_MATH", BattleMode.PRIVATE)), "ACTIVITY_CONFLICT");
        assertThat(battleCount()).isZero();
    }

    @Test void cancellationAndFinishedBattleFreeBothPlayersForNextActivity() {
        var a = register(); var b = register(); matchmaking.search(id(a), "SAT_MATH");
        var matched = matchmaking.search(id(b), "SAT_MATH");
        processor.surrender(matched.getBattleId(), id(a));
        assertThat(matchmaking.activity(id(a)).getType()).isEqualTo(ActivityType.NONE);
        assertThat(matchmaking.activity(id(b)).getType()).isEqualTo(ActivityType.NONE);
        assertThat(matchmaking.createDuel(id(a), "SAT_MATH").getStatus()).isEqualTo(DuelStatus.WAITING);
        assertThat(matchmaking.search(id(b), "SAT_RW").getStatus()).isEqualTo(QueueStatus.SEARCHING);
    }

    @Test void failedBattleFlushRollsBackQueueTransitionAndCanRetryWithoutDuplicateBattle() {
        var a = register(); var b = register(); var first = matchmaking.search(id(a), "SAT_MATH");
        events.values.clear();
        doAnswer(invocation -> { invocation.callRealMethod(); throw new IllegalStateException("Test-only failure after battle flush"); }).when(battles).create(any());
        assertThatThrownBy(() -> matchmaking.search(id(b), "SAT_MATH")).isInstanceOf(IllegalStateException.class);
        assertThat(battleCount()).isZero(); assertThat(events.values).isEmpty();
        assertThat(matchmaking.entry(id(a), first.getId()).getStatus()).isEqualTo(QueueStatus.SEARCHING);
        assertThat(matchmaking.activity(id(b)).getType()).isEqualTo(ActivityType.NONE);
        org.mockito.Mockito.reset(battles);
        var success = matchmaking.search(id(b), "SAT_MATH");
        assertThat(success.getStatus()).isEqualTo(QueueStatus.MATCHED); assertThat(battleCount()).isEqualTo(1);
    }

    @Test void outerTransactionRollbackRestoresWaitingRoomAndPublishesNothing() {
        var host = register(); var guest = register(); var room = matchmaking.createDuel(id(host), "SAT_MATH");
        events.values.clear();
        assertThatThrownBy(() -> new TransactionTemplate(transactions).executeWithoutResult(status -> {
            matchmaking.join(id(guest), room.getCode());
            assertThat(battleCount()).isEqualTo(1); assertThat(events.values).isEmpty();
            throw new IllegalStateException("Test-only outer rollback");
        })).isInstanceOf(IllegalStateException.class);
        assertThat(battleCount()).isZero(); assertThat(events.values).isEmpty();
        assertThat(matchmaking.duel(id(host), room.getId()).getStatus()).isEqualTo(DuelStatus.WAITING);
        assertThat(matchmaking.activity(id(host)).getType()).isEqualTo(ActivityType.PRIVATE_DUEL);
        assertThat(matchmaking.activity(id(guest)).getType()).isEqualTo(ActivityType.NONE);
        assertThat(matchmaking.join(id(guest), room.getCode()).getBattleId()).isNotNull();
    }

    @ParameterizedTest @ValueSource(booleans = {false, true})
    void competingActivityWaitsForOuterCommitOrRollback(boolean rollback) throws Exception {
        var user = register();
        CountDownLatch staged = new CountDownLatch(1), finish = new CountDownLatch(1), challengerStarted = new CountDownLatch(1);
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            var first = executor.submit(() -> {
                new TransactionTemplate(transactions).executeWithoutResult(status -> {
                    matchmaking.createDuel(id(user), "SAT_MATH");
                    staged.countDown();
                    try { if (!finish.await(5, TimeUnit.SECONDS)) throw new IllegalStateException("Test transaction was not released"); }
                    catch (InterruptedException ex) { Thread.currentThread().interrupt(); throw new IllegalStateException(ex); }
                    if (rollback) status.setRollbackOnly();
                });
            });
            Future<Object> challenger;
            try {
                assertThat(staged.await(5, TimeUnit.SECONDS)).isTrue();
                challenger = executor.submit(() -> {
                    challengerStarted.countDown();
                    try { return matchmaking.search(id(user), "SAT_RW"); }
                    catch (BusinessException ex) { return ex.getCode(); }
                });
                assertThat(challengerStarted.await(5, TimeUnit.SECONDS)).isTrue();
                assertThatThrownBy(() -> challenger.get(150, TimeUnit.MILLISECONDS)).isInstanceOf(TimeoutException.class);
                assertThat(events.values).isEmpty();
            } finally { finish.countDown(); }
            first.get(5, TimeUnit.SECONDS);
            Object result = challenger.get(5, TimeUnit.SECONDS);
            if (rollback) {
                assertThat(result).isInstanceOf(QueueEntryDto.class);
                assertThat(matchmaking.activity(id(user)).getType()).isEqualTo(ActivityType.QUEUE);
            } else {
                assertThat(result).isEqualTo("ACTIVITY_CONFLICT");
                assertThat(matchmaking.activity(id(user)).getType()).isEqualTo(ActivityType.PRIVATE_DUEL);
            }
            assertThat(events.values).hasSize(1);
        }
    }

    @Test void restartLosesMemoryActivitiesAndExistingBattleRecoveryStillCancelsWithoutElo() {
        var queued = register(); var host = register(); var a = register(); var b = register();
        var entry = matchmaking.search(id(queued), "SAT_RW");
        var room = matchmaking.createDuel(id(host), "SAT_MATH");
        UUID battleId = processor.create(new CreateBattleDto(id(a), id(b), "SAT_MATH", BattleMode.RANKED));
        var fresh = new MatchmakingProcessorImpl(new MatchmakingRegistryServiceImpl(transactions, publisher, clock), battles, processor, users, ratings, ratingProcessor, usage, subscriptions, questions, disciplines, properties, clock, invitations);
        assertThat(fresh.activity(id(queued)).getType()).isEqualTo(ActivityType.NONE);
        assertThat(fresh.activity(id(host)).getType()).isEqualTo(ActivityType.NONE);
        assertCode(() -> fresh.entry(id(queued), entry.getId()), "QUEUE_ENTRY_NOT_FOUND");
        assertCode(() -> fresh.duel(id(host), room.getId()), "DUEL_NOT_FOUND");
        assertThat(fresh.activity(id(a)).getBattleId()).isEqualTo(battleId);
        recovery.recover();
        assertThat(fresh.activity(id(a)).getType()).isEqualTo(ActivityType.NONE);
        assertThat(processor.result(battleId, id(a)).getReason()).isEqualTo(CompletionReason.SERVER_INTERRUPTION);
        assertThat(ratings.getByUserId(id(a))).allSatisfy(item -> assertThat(item.getRating()).isEqualTo(1000));
    }

    @Test void httpContractEnforcesOwnersValidationAuthAndExplicitNullActivity() throws Exception {
        var a = register(); var b = register();
        mvc.perform(get("/api/v1/users/me/activity")).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/v1/duels").header("Authorization", "Bearer " + a.getTokens().getRefreshToken()).contentType("application/json").content("{\"disciplineCode\":\"SAT_MATH\",\"format\":\"STANDARD\"}")).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/v1/matchmaking/entries").header("Authorization", bearer(a)).contentType("application/json").content("{\"disciplineCode\":\"SAT\"}")).andExpect(status().isBadRequest());
        mvc.perform(post("/api/v1/duels").header("Authorization", bearer(a)).contentType("application/json").content("{\"disciplineCode\":\"SAT_MATH\",\"format\":\"STANDARD\",\"extra\":1}")).andExpect(status().isBadRequest());
        var none = json.readTree(mvc.perform(get("/api/v1/users/me/activity").header("Authorization", bearer(a))).andExpect(status().isOk()).andReturn().getResponse().getContentAsString());
        assertThat(none.has("resourceId")).isTrue(); assertThat(none.path("resourceId").isNull()).isTrue(); assertThat(none.path("battleId").isNull()).isTrue();
        var entry = json.readTree(mvc.perform(post("/api/v1/matchmaking/entries").header("Authorization", bearer(a)).contentType("application/json").content("{\"disciplineCode\":\"SAT_MATH\",\"format\":\"STANDARD\"}")).andExpect(status().isCreated()).andReturn().getResponse().getContentAsString());
        assertThat(entry.fieldNames()).toIterable().containsExactlyInAnyOrder("id", "disciplineCode", "format", "status", "createdAt", "expiresAt", "ratingWindow", "battleId", "version", "error");
        mvc.perform(get("/api/v1/matchmaking/entries/" + entry.path("id").asText()).header("Authorization", bearer(b))).andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value("QUEUE_ENTRY_NOT_FOUND"));
        mvc.perform(delete("/api/v1/matchmaking/entries/" + entry.path("id").asText()).header("Authorization", bearer(b))).andExpect(status().isNotFound());
        mvc.perform(delete("/api/v1/matchmaking/entries/" + entry.path("id").asText()).header("Authorization", bearer(a))).andExpect(status().isNoContent()).andExpect(content().string(""));
        var room = json.readTree(mvc.perform(post("/api/v1/duels").header("Authorization", bearer(a)).contentType("application/json").content("{\"disciplineCode\":\"SAT_MATH\",\"format\":\"STANDARD\"}")).andExpect(status().isCreated()).andReturn().getResponse().getContentAsString());
        mvc.perform(get("/api/v1/duels/" + room.path("id").asText()).header("Authorization", bearer(b))).andExpect(status().isNotFound());
        mvc.perform(post("/api/v1/duels/join").header("Authorization", bearer(b)).contentType("application/json").content("{\"code\":\"bad\"}")).andExpect(status().isBadRequest());
        mvc.perform(post("/api/v1/duels/join").header("Authorization", bearer(b)).contentType("application/json").content(json.writeValueAsString(Map.of("code", " " + room.path("code").asText().toLowerCase(Locale.ROOT) + " ")))).andExpect(status().isOk()).andExpect(jsonPath("$.status").value("MATCHED"));
        mvc.perform(get("/api/v1/duels/" + room.path("id").asText()).header("Authorization", bearer(b))).andExpect(status().isOk());
        mvc.perform(delete("/api/v1/duels/" + room.path("id").asText()).header("Authorization", bearer(b))).andExpect(status().isNotFound());
        mvc.perform(delete("/api/v1/duels/" + room.path("id").asText()).header("Authorization", bearer(a))).andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("MATCH_ALREADY_FOUND"));
        mvc.perform(get("/api/v1/users/me/activity").header("Authorization", bearer(b))).andExpect(status().isOk()).andExpect(jsonPath("$.type").value("BATTLE"));
    }

    @Test void realPrivateEventsWaitForCommitAreIsolatedAndPrivateFinishDoesNotChangeElo() throws Exception {
        var host = register(); var guest = register(); var unrelated = register();
        var a = connect(host); var b = connect(guest); var c = connect(unrelated);
        var room = matchmaking.createDuel(id(host), "SAT_MATH");
        var waiting = a.event(item -> "PRIVATE_DUEL_CHANGED".equals(item.path("type").asText()));
        assertThat(waiting.path("data").path("code").asText()).isEqualTo(room.getCode());
        assertThat(b.hasMessage(Duration.ofMillis(120))).isFalse(); assertThat(c.hasMessage(Duration.ofMillis(120))).isFalse();
        new TransactionTemplate(transactions).executeWithoutResult(status -> {
            matchmaking.join(id(guest), room.getCode());
            try { assertThat(a.hasMessage(Duration.ofMillis(150))).isFalse(); assertThat(b.hasMessage(Duration.ofMillis(150))).isFalse(); }
            catch (Exception ex) { throw new IllegalStateException(ex); }
        });
        var ah = a.event(item -> "PRIVATE_DUEL_CHANGED".equals(item.path("type").asText()) && "MATCHED".equals(item.path("data").path("status").asText()));
        var bg = b.event(item -> "PRIVATE_DUEL_CHANGED".equals(item.path("type").asText()) && "MATCHED".equals(item.path("data").path("status").asText()));
        assertThat(ah.path("data").path("battleId").asText()).isEqualTo(bg.path("data").path("battleId").asText());
        assertThat(ah.path("version").asInt()).isEqualTo(ah.path("data").path("version").asInt()).isEqualTo(2);
        assertThat(ah.path("eventId").asText()).isEqualTo(bg.path("eventId").asText());
        assertThat(ah.toString()).doesNotContain("email", "userId", "password");
        UUID battleId = UUID.fromString(ah.path("data").path("battleId").asText());
        processor.ready(battleId, id(host)); processor.ready(battleId, id(guest));
        clock.set(START.plusSeconds(4)); processor.tick(battleId); processor.surrender(battleId, id(host));
        assertThat(processor.snapshot(battleId, id(host)).getPhase()).isEqualTo(BattlePhase.FINISHED);
        assertThat(processor.result(battleId, id(host)).getPlayers()).allSatisfy(player -> assertThat(player.getRatingDelta()).isZero());
        for (var user : List.of(host, guest)) {
            assertThat(ratings.getByUserId(id(user))).allSatisfy(item -> assertThat(item.getRating()).isEqualTo(1000));
            assertThat(matchmaking.activity(id(user)).getType()).isEqualTo(ActivityType.NONE);
        }
        assertThat(c.hasMessage(Duration.ofMillis(120))).isFalse();
    }

    @Test void realQueueEventsAreOwnerOnlyContainBattleIdAndRollbackPublishesNothing() throws Exception {
        var first = register(); var second = register(); var unrelated = register();
        var a = connect(first); var b = connect(second); var c = connect(unrelated);
        var entry = matchmaking.search(id(first), "SAT_MATH");
        a.event(item -> "QUEUE_CHANGED".equals(item.path("type").asText()) && "SEARCHING".equals(item.path("data").path("status").asText()));
        assertThat(b.hasMessage(Duration.ofMillis(100))).isFalse();
        assertThatThrownBy(() -> new TransactionTemplate(transactions).executeWithoutResult(status -> {
            matchmaking.search(id(second), "SAT_MATH"); throw new IllegalStateException("Test-only rollback");
        })).isInstanceOf(IllegalStateException.class);
        assertThat(a.hasMessage(Duration.ofMillis(150))).isFalse(); assertThat(b.hasMessage(Duration.ofMillis(150))).isFalse();
        assertThat(battleCount()).isZero();
        var matched = matchmaking.search(id(second), "SAT_MATH");
        var ae = a.event(item -> "QUEUE_CHANGED".equals(item.path("type").asText()) && "MATCHED".equals(item.path("data").path("status").asText()));
        var be = b.event(item -> "QUEUE_CHANGED".equals(item.path("type").asText()) && "MATCHED".equals(item.path("data").path("status").asText()));
        assertThat(ae.path("resourceId").asText()).isEqualTo(entry.getId().toString());
        assertThat(ae.path("data").path("battleId").asText()).isEqualTo(be.path("data").path("battleId").asText()).isEqualTo(matched.getBattleId().toString());
        assertThat(ae.path("data").has("rating")).isFalse(); assertThat(ae.path("data").has("userId")).isFalse();
        assertThat(c.hasMessage(Duration.ofMillis(150))).isFalse();
    }

    private AuthDto register() {
        var dto = new RegisterDto(); dto.setBirthYear(2000); dto.setBirthMonth(1); var suffix = UUID.randomUUID().toString().replace("-", "").substring(0, 12);
        dto.setEmail(suffix + "@example.com"); dto.setNickname("Queue_" + suffix); dto.setPassword("ExamplePass123!"); return auth.register(dto);
    }
    private UUID id(AuthDto user) { return user.getUser().getId(); }
    private String bearer(AuthDto user) { return "Bearer " + user.getTokens().getAccessToken(); }
    private void rating(AuthDto user, String disciplineCode, int rating) { jdbc.update("UPDATE ratings SET rating=? WHERE user_id=? AND discipline_code=?", rating, id(user), disciplineCode); }
    private long battleCount() { return jdbc.queryForObject("SELECT count(*) FROM battles", Long.class); }
    private NativeStompClient connect(AuthDto user) throws Exception {
        var client = new NativeStompClient(http, URI.create("ws://localhost:" + port + "/ws/v1/events"), "http://localhost:" + port, json);
        clients.add(client); client.connect(user.getTokens().getAccessToken()); client.await("CONNECTED"); client.startHeartbeats(); client.subscribe("/user/queue/events");
        await().atMost(Duration.ofSeconds(5)).until(() -> sessions.current(id(user)).isPresent()); return client;
    }
    private List<Object> race(Callable<?> left, Callable<?> right) throws Exception {
        CountDownLatch start = new CountDownLatch(1);
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            var a = executor.submit(() -> attempt(start, left)); var b = executor.submit(() -> attempt(start, right));
            start.countDown(); return List.of(a.get(8, TimeUnit.SECONDS), b.get(8, TimeUnit.SECONDS));
        }
    }
    private Object attempt(CountDownLatch start, Callable<?> action) throws Exception {
        start.await(); try { return action.call(); } catch (BusinessException ex) { return ex.getCode(); }
    }
    private static void assertCode(org.assertj.core.api.ThrowableAssert.ThrowingCallable action, String code) {
        assertThatThrownBy(action).isInstanceOfSatisfying(BusinessException.class, ex -> assertThat(ex.getCode()).isEqualTo(code));
    }
}
