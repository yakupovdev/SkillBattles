package com.skillbattles.backend;

import com.fasterxml.jackson.databind.*;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.processor.*;
import com.skillbattles.backend.service.*;
import jakarta.persistence.EntityManagerFactory;
import org.hibernate.SessionFactory;
import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.*;
import org.springframework.context.annotation.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.*;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.web.servlet.MockMvc;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.*;
import java.nio.file.*;
import java.time.*;
import java.util.*;
import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static com.skillbattles.backend.BattleFixtures.*;

@SpringBootTest(properties = {"app.jwt.secret=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
        "app.battle.scheduling.enabled=false", "app.matchmaking.scheduling.enabled=false",
        "app.battle.math.question-limit-seconds=10", "app.battle.english.question-limit-seconds=10"})
@AutoConfigureMockMvc
@Import(HistoryPostgresTest.TestConfig.class)
@Testcontainers(disabledWithoutDocker = true)
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
class HistoryPostgresTest {
    @Container static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:17.12-alpine");
    @DynamicPropertySource static void database(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl); registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
    }
    @TestConfiguration static class TestConfig {
        @Bean @Primary MutableClock testClock() { return new MutableClock(); }
        @Bean @Primary TestPresence testPresence() { return new TestPresence(); }
    }
    @Autowired BattleProcessor processor;
    @Autowired BattleService battles;
    @Autowired AuthProcessor auth;
    @Autowired UserService users;
    @Autowired QuestionService questions;
    @Autowired QuestionImportFileService files;
    @Autowired MutableClock clock;
    @Autowired TestPresence presence;
    @Autowired JdbcTemplate jdbc;
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired EntityManagerFactory entityManagerFactory;

    @BeforeEach void setup() throws Exception {
        uniformTiming(jdbc, 10);
        clock.set(START); presence.clear(); jdbc.execute("TRUNCATE question_reports,ranked_usage, battles, questions");
        questions.importQuestions(fixture(), false);
    }

    @Test void historyUsesSavedCallerRelativeResultAcrossRankedPrivateCancelledAndFilters() throws Exception {
        var a = register(); var b = register(); var outsider = register();
        UUID ranked = create(a, b, "SAT_MATH", BattleMode.RANKED); start(ranked, a, b); finish(ranked, a, b, false);
        UUID privateId = create(a, b, "SAT_RW", BattleMode.PRIVATE); start(privateId, a, b); finish(privateId, a, b, true);
        UUID cancelled = create(a, b, "SAT_MATH", BattleMode.RANKED); processor.surrender(cancelled, id(a));
        UUID active = create(a, b, "SAT_MATH", BattleMode.RANKED);
        JsonNode history = history(a, "");
        assertThat(history.path("pagination").path("totalElements").asInt()).isEqualTo(3);
        assertThat(history.path("pagination").path("size").asInt()).isEqualTo(20);
        assertThat(history.path("data").findValuesAsText("battleId")).doesNotContain(active.toString());
        for (UUID battleId : List.of(ranked, privateId, cancelled)) for (var caller : List.of(a, b)) {
            JsonNode item = find(history(caller, "").path("data"), battleId);
            JsonNode result = result(caller, battleId, 200);
            assertThat(item.path("outcome")).isEqualTo(result.path("myOutcome"));
            assertThat(item.path("reason")).isEqualTo(result.path("reason"));
            var own = playerResult(result, id(caller));
            var opponent = playerResult(result, id(caller).equals(id(a)) ? id(b) : id(a));
            assertThat(item.path("myScore")).isEqualTo(own.path("score"));
            assertThat(item.path("opponentScore")).isEqualTo(opponent.path("score"));
            assertThat(item.path("ratingDelta")).isEqualTo(own.path("ratingDelta"));
            assertThat(item.path("opponent").path("id")).isEqualTo(opponent.path("id"));
            assertThat(item.path("finishedAt")).isEqualTo(result.path("finishedAt"));
        }
        assertThat(find(history.path("data"), ranked).path("ratingDelta").asInt()).isEqualTo(32);
        assertThat(find(history.path("data"), privateId).path("ratingDelta").asInt()).isZero();
        assertThat(find(history.path("data"), cancelled).path("outcome").asText()).isEqualTo("CANCELLED");
        assertThat(history(a, "?disciplineCode=SAT_RW&mode=PRIVATE").path("data").size()).isEqualTo(1);
        assertThat(history(a, "?disciplineCode=SAT_MATH&mode=PRIVATE").path("data").isEmpty()).isTrue();
        assertThat(history(outsider, "").path("data").isEmpty()).isTrue();
        JsonNode stats = getJson("/api/v1/users/me/statistics", a, 200);
        JsonNode math = stats.path("disciplines").get(0), english = stats.path("disciplines").get(1);
        assertThat(math.path("ranked").path("played").asInt()).isEqualTo(1);
        assertThat(math.path("ranked").path("wins").asInt()).isEqualTo(1);
        assertThat(english.path("privateMatches").path("draws").asInt()).isEqualTo(1);
    }

    @Test void paginationIsStableWithEqualCreatedAtAndAppliesFiltersBeforeCount() throws Exception {
        var a = register(); var b = register();
        List<UUID> ids = new ArrayList<>();
        for (int i = 0; i < 23; i++) {
            UUID battle = create(a, b, i % 2 == 0 ? "SAT_MATH" : "SAT_RW", i % 3 == 0 ? BattleMode.PRIVATE : BattleMode.RANKED);
            processor.surrender(battle, id(a)); ids.add(battle);
        }
        var first = history(a, ""); var second = history(a, "?page=1"); var beyond = history(a, "?page=2");
        assertThat(first.path("data").size()).isEqualTo(20); assertThat(second.path("data").size()).isEqualTo(3);
        assertThat(first.path("pagination").path("totalPages").asInt()).isEqualTo(2);
        assertThat(beyond.path("data").isEmpty()).isTrue();
        List<String> joined = new ArrayList<>(first.path("data").findValuesAsText("battleId")); joined.addAll(second.path("data").findValuesAsText("battleId"));
        assertThat(joined).doesNotHaveDuplicates().containsExactlyInAnyOrderElementsOf(ids.stream().map(UUID::toString).toList());
        var ascending = history(a, "?sort=createdAt,asc&size=100").path("data").findValuesAsText("battleId");
        Collections.reverse(joined); assertThat(ascending).containsExactlyElementsOf(joined);
        assertThat(history(a, "?disciplineCode=SAT_RW").path("pagination").path("totalElements").asInt()).isEqualTo(11);
        var distant = history(a, "?page=2147483647&size=100");
        assertThat(distant.path("data").isEmpty()).isTrue();
        assertThat(distant.path("pagination").path("totalElements").asInt()).isEqualTo(23);
    }

    @ParameterizedTest
    @ValueSource(strings = {"?page=-1", "?size=0", "?size=101", "?sort=score,desc", "?sort=createdAt", "?sort=createdAt,DESC",
            "?page=abc", "?page=2147483648", "?disciplineCode=SAT", "?mode=SOLO", "?sort=", "?disciplineCode=", "?mode=", "?page=", "?size="})
    void invalidQueryValuesReturnContractValidationError(String query) throws Exception {
        var user = register();
        assertThat(getJson("/api/v1/users/me/battles" + query, user, 400).path("code").asText()).isEqualTo("VALIDATION_ERROR");
    }

    @Test void reviewOnlyShowsStartedRoundsAndAcceptedIncompleteAnswersWithoutChangingFinalScores() throws Exception {
        var a = register(); var b = register(); var outsider = register();
        UUID battleId = create(a, b, "SAT_MATH", BattleMode.RANKED); start(battleId, a, b);
        var first = battles.lock(battleId); Instant deadline = round(first).getDeadline();
        processor.answer(battleId, id(a), answer(first, true), clock.instant());
        clock.set(deadline); processor.tick(battleId); // One accepted answer and one real timeout.
        clock.set(round(battles.lock(battleId)).getRevealEndsAt()); processor.tick(battleId);
        var second = battles.lock(battleId);
        processor.answer(battleId, id(a), answer(second, true), clock.instant());
        processor.surrender(battleId, id(b));
        var before = persisted(battleId);
        var review = getJson("/api/v1/battles/" + battleId + "/review", a, 200);
        assertThat(review.path("rounds").size()).isEqualTo(2);
        assertThat(review.path("rounds").get(0).path("completed").asBoolean()).isTrue();
        assertThat(review.path("rounds").get(0).path("answers").size()).isEqualTo(2);
        var timeout = review.path("rounds").get(0).path("answers").get(1);
        assertThat(timeout.path("timedOut").asBoolean()).isTrue(); assertThat(timeout.path("selectedOptionId").isNull()).isTrue();
        assertThat(timeout.path("elapsedMs").isNull()).isTrue(); assertThat(timeout.path("points").asInt()).isZero();
        var incomplete = review.path("rounds").get(1);
        assertThat(incomplete.path("completed").asBoolean()).isFalse(); assertThat(incomplete.path("answers").size()).isEqualTo(1);
        assertThat(incomplete.path("answers").get(0).path("points").asInt()).isEqualTo(1100);
        assertThat(incomplete.path("question").path("explanation").asText()).startsWith("TEST ONLY");
        assertThat(playerResult(result(a, battleId, 200), id(a)).path("score").asInt()).isEqualTo(1000); // Incomplete round awards nothing.
        var otherReview=getJson("/api/v1/battles/" + battleId + "/review", b, 200);
        assertThat(otherReview.path("rounds")).isEqualTo(review.path("rounds"));
        assertThat(otherReview.path("answerAccess").path("canViewCorrectAnswer").asBoolean()).isTrue();
        // entitlementVersion belongs to the caller; it need not match the opponent's version.
        for (int i = 0; i < 3; i++) { result(a, battleId, 200); history(a, ""); getJson("/api/v1/battles/" + battleId + "/review", a, 200); getJson("/api/v1/users/me/statistics", a, 200); }
        assertThat(persisted(battleId)).isEqualTo(before);
        assertPrivate(review); assertPrivate(history(a, ""));
        assertThat(getJson("/api/v1/battles/" + battleId + "/review", outsider, 404).path("code").asText()).isEqualTo("BATTLE_NOT_FOUND");
        result(outsider, battleId, 404);
    }

    @Test void cancellationReviewHasNoFutureRoundsAndReadEndpointsDoNotAdvanceOverdueBattle() throws Exception {
        var a = register(); var b = register(); var outsider = register();
        UUID battleId = create(a, b, "SAT_MATH", BattleMode.RANKED);
        var before = persisted(battleId); clock.set(START.plusSeconds(60));
        assertThat(result(a, battleId, 409).path("code").asText()).isEqualTo("BATTLE_NOT_FINISHED");
        assertThat(getJson("/api/v1/battles/" + battleId + "/review", a, 409).path("code").asText()).isEqualTo("BATTLE_NOT_FINISHED");
        assertThat(history(a, "").path("data").isEmpty()).isTrue();
        assertThat(persisted(battleId)).isEqualTo(before);
        getJson("/api/v1/battles/" + battleId + "/review", outsider, 404);
        getJson("/api/v1/battles/" + UUID.randomUUID() + "/review", a, 404);
        processor.tick(battleId);
        var review = getJson("/api/v1/battles/" + battleId + "/review", a, 200);
        assertThat(review.path("rounds").isEmpty()).isTrue();
        assertThat(result(a, battleId, 200).path("reason").asText()).isEqualTo("READY_TIMEOUT");
        assertThat(history(a, "").path("data").get(0).path("ratingDelta").asInt()).isZero();
        mvc.perform(get("/api/v1/users/me/battles")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/v1/battles/" + battleId + "/review")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/v1/users/me/battles").header("Authorization", "Bearer " + a.getTokens().getRefreshToken())).andExpect(status().isUnauthorized());
    }

    @Test void interruptionAfterStartKeepsIncompleteReviewAndFrozenContentSurvivesRevisionAndUserDeletion() throws Exception {
        var a = register(); var b = register();
        UUID battleId = create(a, b, "SAT_MATH", BattleMode.RANKED); start(battleId, a, b);
        var saved = battles.lock(battleId); var selected = round(saved).getQuestion();
        processor.answer(battleId, id(a), answer(saved, true), clock.instant()); processor.interrupt(battleId);
        JsonNode original = getJson("/api/v1/battles/" + battleId + "/review", a, 200);
        assertThat(original.path("rounds").size()).isEqualTo(1);
        assertThat(original.path("rounds").get(0).path("completed").asBoolean()).isFalse();
        assertThat(result(a, battleId, 200).path("myOutcome").asText()).isEqualTo("CANCELLED");
        assertThat(playerResult(result(a, battleId, 200), id(a)).path("score").asInt()).isZero();
        String key = jdbc.queryForObject("SELECT external_key FROM questions WHERE id=?", String.class, selected.getId());
        var revision = fixture().stream().filter(item -> item.getExternalKey().equals(key)).findFirst().orElseThrow();
        revision.setContentVersion(2); revision.setPrompt("TEST ONLY revised prompt"); revision.setExplanation("TEST ONLY revised explanation");
        questions.importQuestions(List.of(revision), false);
        jdbc.update("UPDATE questions SET deleted=true, active=false WHERE id=?", selected.getId());
        users.softDelete(id(b));
        assertThat(getJson("/api/v1/battles/" + battleId + "/review", a, 200)).isEqualTo(original);
        assertThat(history(a, "").path("data").get(0).path("opponent").path("nickname").asText()).isEqualTo(b.getUser().getNickname());
        assertPrivate(original);
        jdbc.update("UPDATE battles SET deleted=true WHERE id=?", battleId);
        assertThat(history(a, "").path("data").isEmpty()).isTrue(); result(a, battleId, 404);
        getJson("/api/v1/battles/" + battleId + "/review", a, 404);
    }

    @Test void historyReportsActualFlooredRatingDeltaAndDoesNotRecalculateIt() throws Exception {
        var a = register(); var b = register();
        jdbc.update("UPDATE ratings SET rating=0 WHERE user_id IN (?,?) AND discipline_code='SAT_MATH'", id(a), id(b));
        UUID battleId = create(a, b, "SAT_MATH", BattleMode.RANKED); start(battleId, a, b); processor.surrender(battleId, id(a));
        assertThat(history(a, "").path("data").get(0).path("ratingDelta").asInt()).isZero();
        assertThat(history(b, "").path("data").get(0).path("ratingDelta").asInt()).isEqualTo(32);
        assertThat(result(a, battleId, 200).path("myOutcome").asText()).isEqualTo("LOSS");
    }

    @Test void historyUsesTwoQueriesForFullPageWithoutLoadingQuestionStateOrOpponentEntities() {
        var a = register(); var b = register();
        for (int i = 0; i < 23; i++) { var battleId = create(a, b, "SAT_MATH", BattleMode.PRIVATE); processor.surrender(battleId, id(a)); }
        var statistics = entityManagerFactory.unwrap(SessionFactory.class).getStatistics();
        statistics.setStatisticsEnabled(true); statistics.clear();
        try {
            var page = battles.history(new BattleHistoryQueryDto(id(a), 0, 20, "createdAt,desc", null, null));
            assertThat(page.getData()).hasSize(20); assertThat(page.getPagination().getTotalElements()).isEqualTo(23);
            assertThat(statistics.getPrepareStatementCount()).isEqualTo(2);
            assertThat(statistics.getEntityLoadCount()).isZero();
            assertThat(statistics.getEntityUpdateCount()).isZero();
        } finally { statistics.setStatisticsEnabled(false); }
        var indexes = jdbc.queryForList("SELECT indexdef FROM pg_indexes WHERE tablename='battles' AND indexname LIKE '%_history'", String.class);
        assertThat(indexes).hasSize(2).allSatisfy(sql -> assertThat(sql).contains("created_at DESC", "id DESC", "FINISHED", "CANCELLED"));
    }

    private UUID create(AuthDto a, AuthDto b, String disciplineCode, BattleMode mode) {
        presence.connect(id(a), clock.instant()); presence.connect(id(b), clock.instant());
        return processor.create(new CreateBattleDto(id(a), id(b), disciplineCode, mode));
    }
    private void start(UUID battleId, AuthDto a, AuthDto b) {
        processor.ready(battleId, id(a)); processor.ready(battleId, id(b));
        clock.set(clock.instant().plusSeconds(3)); processor.tick(battleId);
    }
    private void finish(UUID battleId, AuthDto a, AuthDto b, boolean draw) {
        while (battles.lock(battleId).getPhase() == BattlePhase.QUESTION) {
            var state = battles.lock(battleId);
            processor.answer(battleId, id(a), answer(state, true), clock.instant());
            processor.answer(battleId, id(b), answer(state, draw), clock.instant());
            clock.set(round(battles.lock(battleId)).getRevealEndsAt()); processor.tick(battleId);
        }
    }
    private Map<String, Object> persisted(UUID battleId) {
        return jdbc.queryForMap("SELECT version, updated_at, state::text, result::text, settled_at FROM battles WHERE id=?", battleId);
    }
    private List<QuestionImportDto> fixture() throws Exception { return files.read(Path.of(Objects.requireNonNull(getClass().getResource("/fixtures/stage2-questions-test-only.json")).toURI())); }
    private JsonNode history(AuthDto user, String query) throws Exception { return getJson("/api/v1/users/me/battles" + query, user, 200); }
    private JsonNode result(AuthDto user, UUID battleId, int expected) throws Exception { return getJson("/api/v1/battles/" + battleId + "/result", user, expected); }
    private JsonNode getJson(String path, AuthDto user, int expected) throws Exception {
        var response = mvc.perform(get(path).header("Authorization", "Bearer " + user.getTokens().getAccessToken())).andExpect(status().is(expected)).andReturn().getResponse();
        return json.readTree(response.getContentAsString());
    }
    private static JsonNode find(JsonNode data, UUID battleId) { for (var item : data) if (item.path("battleId").asText().equals(battleId.toString())) return item; throw new AssertionError("Missing history battle"); }
    private static JsonNode playerResult(JsonNode result, UUID id) { for (var player : result.path("players")) if (player.path("id").asText().equals(id.toString())) return player; throw new AssertionError("Missing participant"); }
    private void assertPrivate(JsonNode value) { assertThat(value.toString()).doesNotContain("email", "password", "Token", "submissionId", "acceptedAt", "sessionId"); }
    private UUID id(AuthDto user) { return user.getUser().getId(); }
    private AuthDto register() {
        var dto = new RegisterDto(); dto.setBirthYear(2000); dto.setBirthMonth(1); String suffix = UUID.randomUUID().toString().replace("-", "").substring(0, 12);
        dto.setEmail(suffix + "@example.com"); dto.setNickname("History_" + suffix); dto.setPassword("ExamplePass123!"); var user=auth.register(dto);
        // Internal fixture: old full-history/revision tests exercise the Pro view. No public switch exists.
        jdbc.update("UPDATE subscription_accounts SET plan_code='PRO_MONTHLY',status='ACTIVE',paid=true,pro_active=true,current_period_start=?,current_period_end=? WHERE user_id=?",java.sql.Timestamp.from(clock.instant().minusSeconds(1)),java.sql.Timestamp.from(clock.instant().plusSeconds(3600)),id(user));
        return user;
    }
}
