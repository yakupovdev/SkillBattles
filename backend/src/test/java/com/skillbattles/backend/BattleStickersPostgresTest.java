package com.skillbattles.backend;

import com.fasterxml.jackson.databind.*;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.processor.*;
import com.skillbattles.backend.service.*;
import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.*;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.context.annotation.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.*;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.security.oauth2.jwt.*;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import com.skillbattles.backend.config.JwtProperties;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.*;
import java.net.URI;
import java.net.http.*;
import java.nio.file.*;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import static org.assertj.core.api.Assertions.*;
import static org.awaitility.Awaitility.await;
import static com.skillbattles.backend.BattleFixtures.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {
        "app.jwt.secret=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=", "app.battle.scheduling.enabled=false",
        "app.battle.math.question-count=2", "app.battle.math.question-limit-seconds=60", "app.realtime.monitor-ms=3600000"})
@Import(BattleStickersPostgresTest.TimeConfig.class)
@Testcontainers(disabledWithoutDocker = true)
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
class BattleStickersPostgresTest {
    @Container static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:17.12-alpine");
    @DynamicPropertySource static void database(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
    }
    @TestConfiguration static class TimeConfig { @Bean @Primary MutableClock testClock() { return new MutableClock(); } }
    @LocalServerPort int port;
    @Autowired ObjectMapper json;
    @Autowired MutableClock clock;
    @Autowired AuthProcessor auth;
    @Autowired BattleProcessor processor;
    @Autowired BattleService battles;
    @Autowired RealtimeSessionService sessions;
    @Autowired QuestionService questions;
    @Autowired QuestionImportFileService files;
    @Autowired JdbcTemplate jdbc;
    @Autowired org.springframework.transaction.PlatformTransactionManager transactionManager;
    @Autowired JwtEncoder encoder;
    @Autowired JwtProperties jwtProperties;
    private final HttpClient http = HttpClient.newHttpClient();
    private final List<NativeStompClient> clients = new ArrayList<>();

    @BeforeEach void setup() throws Exception {
        uniformTiming(jdbc, 60);
        clock.set(START);
        jdbc.execute("TRUNCATE question_reports,ranked_usage, battles, questions");
        questions.importQuestions(files.read(Path.of(Objects.requireNonNull(getClass().getResource("/fixtures/stage2-questions-test-only.json")).toURI())), false);
    }
    @AfterEach void cleanup() throws Exception {
        for (var client : clients) client.close();
        await().atMost(Duration.ofSeconds(5)).until(() -> !sessions.hasSubscribers());
        clients.clear();
        http.close();
    }

    @Autowired SubscriptionService subscriptions;
    @Autowired BattleStickerProcessor stickers;
    @Autowired BattleStickerStateService stickerState;
    @Autowired jakarta.persistence.EntityManagerFactory entityManagerFactory;

    @Test void restNativeStompOpponentOnlyNoEchoAndNoDatabaseWrites() throws Exception {
        var a = register(); var b = register(); var c = register();
        var sa = connect(a, true); var sb = connect(b, true); var sc = connect(c, true);
        UUID id = createBattle(a, b, "SAT_MATH", BattleMode.RANKED);
        // Drain presence notifications before asserting sticker delivery in isolation.
        var before = databaseState();
        var statistics = entityManagerFactory.unwrap(org.hibernate.SessionFactory.class).getStatistics();
        statistics.setStatisticsEnabled(true); long updates = statistics.getEntityUpdateCount();
        var command = Map.of("stickerId", "gg", "submissionId", UUID.randomUUID());
        JsonNode receipt = rest("POST", path(id), a, command, 200);
        var event = sb.event(e -> e.path("type").asText().equals("BATTLE_STICKER"));
        assertThat(event.path("data").path("senderUserId").asText()).isEqualTo(a.getUser().getId().toString());
        assertThat(event.path("resourceId").asText()).isEqualTo(id.toString());
        assertThat(event.path("version").asInt()).isEqualTo(1);
        assertThat(event.path("occurredAt")).isEqualTo(receipt.path("sentAt"));
        assertThat(event.path("data").size()).isEqualTo(5);
        assertThat(rest("POST", path(id), a, command, 200)).isEqualTo(receipt);
        assertThat(sa.hasEvent(e -> e.path("type").asText().equals("BATTLE_STICKER"), Duration.ofMillis(200))).isFalse();
        assertThat(sc.hasEvent(e -> e.path("type").asText().equals("BATTLE_STICKER"), Duration.ofMillis(200))).isFalse();
        assertThat(sb.hasEvent(e -> e.path("type").asText().equals("BATTLE_STICKER"), Duration.ofMillis(200))).isFalse();
        assertThat(statistics.getEntityUpdateCount()).isEqualTo(updates);
        assertThat(databaseState()).isEqualTo(before);
        assertThat(rest("GET", "/api/v1/battles/" + id, a, null, 200).toString()).doesNotContain("sticker", "nextAllowedAt");
    }
    @Test void httpAuthOwnershipRequestShapeAndExactCooldownHeaders() throws Exception {
        var a = register(); var b = register(); var c = register(); UUID id = createBattle(a, b, "SAT_RW", BattleMode.PRIVATE);
        var valid = Map.of("stickerId", "fire", "submissionId", UUID.randomUUID());
        rest("POST", path(id), null, valid, 401);
        request("POST", path(id), a.getTokens().getRefreshToken(), valid, 401);
        rest("POST", path(id), c, valid, 404); rest("POST", path(UUID.randomUUID()), a, valid, 404);
        for (var invalid : List.of(Map.of(), Map.of("stickerId", "gg"), Map.of("stickerId", "", "submissionId", UUID.randomUUID()), Map.of("stickerId", "gg", "submissionId", "invalid"), Map.of("stickerId", "gg", "submissionId", UUID.randomUUID(), "senderUserId", a.getUser().getId()), Map.of("stickerId", "x".repeat(65), "submissionId", UUID.randomUUID()), Map.of("stickerId", 42, "submissionId", UUID.randomUUID())))
            assertThat(rest("POST", path(id), a, invalid, 400).path("code").asText()).isEqualTo("VALIDATION_ERROR");
        assertThat(rest("POST", path(id), a, Map.of("stickerId", "GG", "submissionId", UUID.randomUUID()), 400).path("code").asText()).isEqualTo("INVALID_STICKER_ID");
        rest("POST", path(id), a, valid, 200); clock.set(START.plusMillis(1250));
        var response = http.send(HttpRequest.newBuilder(URI.create("http://localhost:" + port + path(id))).header("Authorization", "Bearer " + a.getTokens().getAccessToken()).header("Content-Type", "application/json").POST(HttpRequest.BodyPublishers.ofString(json.writeValueAsString(Map.of("stickerId", "gg", "submissionId", UUID.randomUUID())))).build(), HttpResponse.BodyHandlers.ofString());
        assertThat(response.statusCode()).isEqualTo(429);
        assertThat(response.headers().firstValue("Retry-After")).contains("3");
        assertThat(response.headers().firstValue("Cache-Control")).contains("no-store");
        assertThat(json.readTree(response.body()).path("resetsAt").asText()).isEqualTo(START.plusSeconds(4).toString());
        clock.set(START.plusSeconds(4)); rest("POST", path(id), a, Map.of("stickerId", "gg", "submissionId", UUID.randomUUID()), 200);
    }
    @ParameterizedTest @org.junit.jupiter.params.provider.EnumSource(BattlePhase.class)
    void allAuthoritativePhasesAndTerminalRetry(BattlePhase phase) throws Exception {
        var a = register(); var b = register(); UUID id = createBattle(a, b, "SAT_MATH", BattleMode.PRIVATE);
        var command = Map.of("stickerId", "gg", "submissionId", UUID.randomUUID()); var receipt = rest("POST", path(id), a, command, 200);
        jdbc.update("UPDATE battles SET phase=?,result=CASE WHEN ? IN ('FINISHED','CANCELLED') THEN '{}'::jsonb ELSE NULL END WHERE id=?", phase.name(), phase.name(), id); clock.set(START.plusSeconds(4));
        rest("POST", path(id), b, Map.of("stickerId", "gg", "submissionId", UUID.randomUUID()), phase == BattlePhase.FINISHED || phase == BattlePhase.CANCELLED ? 409 : 200);
        assertThat(rest("POST", path(id), a, command, 200)).isEqualTo(receipt);
    }
    @Test void offlineReceiptDoesNotReplayOnConnectAndTerminalCleanupKeepsRetry() throws Exception {
        var a = register(); var b = register(); UUID id = createBattle(a, b, "SAT_MATH", BattleMode.PRIVATE);
        var command = Map.of("stickerId", "crying", "submissionId", UUID.randomUUID()); var receipt = rest("POST", path(id), a, command, 200);
        var sb = connect(b, true); assertThat(rest("POST", path(id), a, command, 200)).isEqualTo(receipt);
        assertThat(sb.hasEvent(e -> e.path("type").asText().equals("BATTLE_STICKER"), Duration.ofMillis(200))).isFalse();
        jdbc.update("UPDATE battles SET phase='CANCELLED',result='{}'::jsonb WHERE id=?", id); stickers.cleanExpired();
        assertThat(rest("POST", path(id), a, command, 200)).isEqualTo(receipt);
        clock.set(START.plusSeconds(120)); stickers.cleanExpired();
        assertThat(rest("POST", path(id), a, command, 409).path("code").asText()).isEqualTo("STICKERS_NOT_ALLOWED");
    }
    @Test void realConcurrentSameUserRequestsOneAckAndOneCooldown() throws Exception {
        var a = register(); var b = register(); UUID id = createBattle(a, b, "SAT_RW", BattleMode.RANKED);
        var gate = new CountDownLatch(1);
        try (var executor = Executors.newFixedThreadPool(2)) {
            Callable<Integer> attempt = () -> { gate.await(); var response = http.send(HttpRequest.newBuilder(URI.create("http://localhost:" + port + path(id))).header("Authorization", "Bearer " + a.getTokens().getAccessToken()).header("Content-Type", "application/json").POST(HttpRequest.BodyPublishers.ofString(json.writeValueAsString(Map.of("stickerId", "hmm", "submissionId", UUID.randomUUID())))).build(), HttpResponse.BodyHandlers.discarding()); return response.statusCode(); };
            var f = executor.submit(attempt); var g = executor.submit(attempt); gate.countDown();
            assertThat(List.of(f.get(10, TimeUnit.SECONDS), g.get(10, TimeUnit.SECONDS))).containsExactlyInAnyOrder(200, 429);
        }
    }
    @Test void refreshSessionReplacesOldSocketAndSendProhibitionRemains() throws Exception {
        var a = register(); var b = register(); var old = connect(b, true); var current = connect(b, true); old.closed.get(5, TimeUnit.SECONDS);
        UUID id = createBattle(a, b, "SAT_MATH", BattleMode.PRIVATE);
        rest("POST", path(id), a, Map.of("stickerId", "ez", "submissionId", UUID.randomUUID()), 200);
        current.event(e -> e.path("type").asText().equals("BATTLE_STICKER"));
        assertThat(old.hasEvent(e -> e.path("type").asText().equals("BATTLE_STICKER"), Duration.ofMillis(100))).isFalse();
        current.send("SEND\ndestination:/app/stickers\ncontent-type:application/json\n\n{}\0");
        assertThat(json.readTree(current.await("ERROR").body()).path("code").asText()).isEqualTo("FORBIDDEN");
    }
    @ParameterizedTest @org.junit.jupiter.params.provider.CsvSource({"SAT_MATH,RANKED,false", "SAT_MATH,PRIVATE,true", "SAT_RW,RANKED,true", "SAT_RW,PRIVATE,false"})
    void identicalPolicyForPlansModesAndDisciplines(String discipline, BattleMode mode, boolean pro) throws Exception {
        var a = register(); var b = register();
        if (pro) {
            jdbc.update("UPDATE subscription_accounts SET pro_active=true WHERE user_id=?", a.getUser().getId());
        }
        UUID id = createBattle(a, b, discipline, mode);
        assertThat(rest("POST", path(id), a, Map.of("stickerId", "lol", "submissionId", UUID.randomUUID()), 200).path("senderUserId").asText()).isEqualTo(a.getUser().getId().toString());
    }

    String path(UUID id) { return "/api/v1/battles/" + id + "/stickers"; }
    UUID createBattle(AuthDto a, AuthDto b, String discipline, BattleMode mode) { return processor.create(new CreateBattleDto(a.getUser().getId(), b.getUser().getId(), discipline, mode)); }
    Map<String, Object> databaseState() {
        Map<String, Object> snapshot = new TreeMap<>();
        for (String table : List.of("battles", "ratings", "ranked_usage", "subscription_accounts"))
            snapshot.put(table, jdbc.queryForList("SELECT row_to_json(t)::text AS value FROM " + table + " t ORDER BY row_to_json(t)::text"));
        return snapshot;
    }

    private AuthDto register() {
        RegisterDto request = new RegisterDto(); request.setBirthYear(2000); request.setBirthMonth(1);
        String suffix = UUID.randomUUID().toString().replace("-", "").substring(0, 12);
        request.setEmail(suffix + "@example.com"); request.setNickname("Socket_" + suffix); request.setPassword("ExamplePass123!");
        return auth.register(request);
    }
    private NativeStompClient open() throws Exception {
        var client = new NativeStompClient(http, URI.create("ws://localhost:" + port + "/ws/v1/events"), "http://localhost:" + port, json);
        clients.add(client); return client;
    }
    private NativeStompClient connect(AuthDto user, boolean subscribe) throws Exception {
        var client = open(); client.connect(user.getTokens().getAccessToken());
        var connected = client.await("CONNECTED");
        assertThat(connected.headers().get("version")).isEqualTo("1.2");
        assertThat(connected.headers().get("heart-beat")).isEqualTo("5000,5000");
        client.startHeartbeats();
        if (subscribe) { client.subscribe("/user/queue/events"); online(user); }
        return client;
    }
    private void online(AuthDto user) {
        await().atMost(Duration.ofSeconds(5)).pollInterval(Duration.ofMillis(10)).until(() -> sessions.current(user.getUser().getId()).isPresent());
    }
    private JsonNode rest(String method, String path, AuthDto user, Object body, int expected) throws Exception {
        return request(method, path, user == null ? null : user.getTokens().getAccessToken(), body, expected);
    }
    private JsonNode request(String method, String path, String token, Object body, int expected) throws Exception {
        var builder = HttpRequest.newBuilder(URI.create("http://localhost:" + port + path)).timeout(Duration.ofSeconds(5));
        if (token != null) builder.header("Authorization", "Bearer " + token);
        if (body != null) builder.header("Content-Type", "application/json");
        builder.method(method, body == null ? HttpRequest.BodyPublishers.noBody() : HttpRequest.BodyPublishers.ofString(json.writeValueAsString(body)));
        var response = http.send(builder.build(), HttpResponse.BodyHandlers.ofString());
        assertThat(response.statusCode()).isEqualTo(expected);
        return response.body().isEmpty() ? null : json.readTree(response.body());
    }
}
