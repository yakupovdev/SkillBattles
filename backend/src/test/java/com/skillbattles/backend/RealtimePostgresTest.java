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
@Import(RealtimePostgresTest.TimeConfig.class)
@Testcontainers(disabledWithoutDocker = true)
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
class RealtimePostgresTest {
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
        clock.set(START);
        jdbc.execute("TRUNCATE battles, questions");
        questions.importQuestions(files.read(Path.of(Objects.requireNonNull(getClass().getResource("/fixtures/stage2-questions-test-only.json")).toURI())), false);
    }
    @AfterEach void cleanup() throws Exception {
        for (var client : clients) client.close();
        await().atMost(Duration.ofSeconds(5)).until(() -> !sessions.hasSubscribers());
        clients.clear();
        http.close();
    }

    @Test void realConnectAndSubscribeEstablishPresenceAndReadiness() throws Exception {
        AuthDto first = register(), second = register();
        UUID id = processor.create(new CreateBattleDto(first.getUser().getId(), second.getUser().getId(), Subject.MATH, BattleMode.RANKED));
        NativeStompClient a = connect(first, false);
        assertThat(sessions.current(first.getUser().getId())).isEmpty();
        rest("POST", "/api/v1/battles/" + id + "/readiness", first, Map.of("ready", true), 409);
        a.subscribe("/user/queue/events");
        online(first);
        NativeStompClient b = connect(second, true);
        rest("POST", "/api/v1/battles/" + id + "/readiness", first, Map.of("ready", true), 200);
        JsonNode event = b.event(item -> item.path("data").path("players").get(0).path("ready").asBoolean());
        assertThat(event.path("type").asText()).isEqualTo("BATTLE_CHANGED");
        assertThat(event.path("resourceId").asText()).isEqualTo(id.toString());
        assertThat(event.path("version").asInt()).isEqualTo(event.path("data").path("version").asInt());
        assertThat(UUID.fromString(event.path("eventId").asText())).isNotNull();
        rest("POST", "/api/v1/battles/" + id + "/readiness", second, Map.of("ready", true), 200);
        a.event(item -> "COUNTDOWN".equals(item.path("data").path("phase").asText()));
    }

    @Test void invalidRefreshAndMissingJwtReturnUniformErrorAndCloseRealSocket() throws Exception {
        AuthDto user = register();
        var expiredClaims = JwtClaimsSet.builder().issuer(jwtProperties.getIssuer()).subject(user.getUser().getId().toString())
                .audience(List.of("skillbattles-access")).issuedAt(START.minusSeconds(60)).expiresAt(START.minusSeconds(1))
                .claim("token_use", "access").id(UUID.randomUUID().toString()).build();
        String expired = encoder.encode(JwtEncoderParameters.from(JwsHeader.with(MacAlgorithm.HS256).build(), expiredClaims)).getTokenValue();
        for (String token : new String[] {"invalid-token", user.getTokens().getRefreshToken(), expired, null}) {
            NativeStompClient client = open();
            client.connect(token);
            var frame = client.await("ERROR");
            assertThat(json.readTree(frame.body()).path("code").asText()).isEqualTo("UNAUTHORIZED");
            assertThat(json.readTree(frame.body()).path("fieldErrors").isArray()).isTrue();
            assertThat(frame.body()).doesNotContain(user.getTokens().getRefreshToken());
            client.closed.get(5, TimeUnit.SECONDS);
        }
        assertThat(sessions.current(user.getUser().getId())).isEmpty();
    }

    @ParameterizedTest
    @ValueSource(strings = {"/queue/events", "/queue/events-user-other", "/topic/battles", "/user/another-user/queue/events", "/user/queue/other", "/app/answers"})
    void foreignAndDirectDestinationsAreRejected(String destination) throws Exception {
        var user = register();
        var client = connect(user, false);
        client.subscribe(destination);
        assertThat(json.readTree(client.await("ERROR").body()).path("code").asText()).isEqualTo("FORBIDDEN");
        client.closed.get(5, TimeUnit.SECONDS);
        assertThat(sessions.current(user.getUser().getId())).isEmpty();
    }

    @Test void subscribeBeforeConnectAndClientSendAreRejected() throws Exception {
        var unauthenticated = open();
        unauthenticated.subscribe("/user/queue/events");
        assertThat(json.readTree(unauthenticated.await("ERROR").body()).path("code").asText()).isEqualTo("UNAUTHORIZED");
        var user = register();
        var client = connect(user, true);
        client.send("SEND\ndestination:/app/battles\ncontent-type:application/json\n\n{}\0");
        assertThat(json.readTree(client.await("ERROR").body()).path("code").asText()).isEqualTo("FORBIDDEN");
        client.closed.get(5, TimeUnit.SECONDS);
    }

    @Test void crossOriginAndQueryTokenHandshakesAreRejected() {
        assertThatThrownBy(() -> new NativeStompClient(http, URI.create("ws://localhost:" + port + "/ws/v1/events"), "https://foreign.example", json))
                .hasCauseInstanceOf(WebSocketHandshakeException.class);
        assertThatThrownBy(() -> new NativeStompClient(http, URI.create("ws://localhost:" + port + "/ws/v1/events?access_token=forbidden"), "http://localhost:" + port, json))
                .hasCauseInstanceOf(WebSocketHandshakeException.class);
    }

    @Test void unsubscribeAndGracefulStompDisconnectRemoveReadinessPresence() throws Exception {
        var user = register();
        var client = connect(user, true);
        client.send("UNSUBSCRIBE\nid:events\n\n\0");
        await().atMost(Duration.ofSeconds(5)).until(() -> sessions.current(user.getUser().getId()).isEmpty());
        client.subscribe("/user/queue/events"); online(user);
        client.send("DISCONNECT\nreceipt:goodbye\n\n\0");
        await().atMost(Duration.ofSeconds(5)).until(() -> sessions.current(user.getUser().getId()).isEmpty());
        client.closed.get(5, TimeUnit.SECONDS);
    }

    @Test void privatePreStartCancellationIsDeliveredToBothPlayersWithoutRatingChange() throws Exception {
        AuthDto first = register(), second = register();
        var a = connect(first, true); var b = connect(second, true);
        UUID id = processor.create(new CreateBattleDto(first.getUser().getId(), second.getUser().getId(), Subject.MATH, BattleMode.PRIVATE));
        rest("POST", "/api/v1/battles/" + id + "/surrender", first, null, 200);
        var cancellation = a.event(item -> "CANCELLED".equals(item.path("data").path("phase").asText()));
        b.event(item -> "CANCELLED".equals(item.path("data").path("phase").asText()));
        assertThat(cancellation.path("data").path("result").path("reason").asText()).isEqualTo("SURRENDER");
        assertThat(processor.result(id, first.getUser().getId()).getPlayers()).allSatisfy(player -> assertThat(player.getRatingDelta()).isZero());
    }

    @Test void battleEventsArePersonalAndIsolatedAndRevealOnlyWhenRoundEnds() throws Exception {
        AuthDto first = register(), second = register(), unrelated = register();
        var a = connect(first, true); var b = connect(second, true); var c = connect(unrelated, true);
        UUID id = create(first, second);
        start(id, first, second);
        a.drain(); b.drain(); c.drain();
        clock.set(START.plusSeconds(4));
        var state = battles.lock(id);
        AnswerDto answer = answer(state, true);
        JsonNode receipt = rest("POST", "/api/v1/battles/" + id + "/answers", first, answer, 200);
        assertThat(receipt.has("correct")).isFalse();
        int version = battles.lock(id).getVersion();
        var own = a.event(item -> item.path("version").asInt() == version);
        var opponent = b.event(item -> item.path("version").asInt() == version);
        assertThat(own.path("data").path("round").path("mySelectedOptionId").asText()).isEqualTo(answer.getOptionId().toString());
        assertThat(opponent.path("data").path("round").path("mySelectedOptionId").isNull()).isTrue();
        assertThat(opponent.path("data").path("round").path("reveal").isNull()).isTrue();
        assertThat(opponent.path("data").path("players").get(0).path("score").asInt()).isZero();
        assertThat(opponent.toString()).doesNotContain("correctOptionId", "speedBonus", "explanation", "sessionId", "email");
        assertThat(opponent.path("occurredAt").isTextual()).isTrue();
        assertThat(opponent.path("data").path("serverTime").isTextual()).isTrue();
        assertThat(c.hasMessage(Duration.ofMillis(200))).isFalse();
        rest("POST", "/api/v1/battles/" + id + "/answers", second, answer(state, false), 200);
        JsonNode reveal = b.event(item -> "REVEAL".equals(item.path("data").path("phase").asText()));
        assertThat(reveal.path("data").path("round").path("reveal").path("answers").size()).isEqualTo(2);
        assertThat(reveal.path("data").path("round").path("reveal").path("correctOptionId").asText()).isEqualTo(answer.getOptionId().toString());
        assertThat(c.hasMessage(Duration.ofMillis(200))).isFalse();
    }

    @Test void eventsWaitForCommitAndRollbackPublishesNothing() throws Exception {
        AuthDto first = register(), second = register();
        var a = connect(first, true); var b = connect(second, true);
        UUID id = create(first, second);
        int initial = battles.lock(id).getVersion();
        a.event(item -> item.path("version").asInt() == initial);
        b.event(item -> item.path("version").asInt() == initial);
        a.drain(); b.drain();
        TransactionTemplate transaction = new TransactionTemplate(transactionManager);
        transaction.executeWithoutResult(status -> {
            processor.ready(id, first.getUser().getId());
            try { assertThat(b.hasMessage(Duration.ofMillis(150))).isFalse(); }
            catch (Exception error) { throw new IllegalStateException(error); }
        });
        int committed = battles.lock(id).getVersion();
        a.event(item -> item.path("version").asInt() == committed);
        b.event(item -> item.path("version").asInt() == committed);
        a.drain(); b.drain();
        assertThatThrownBy(() -> transaction.executeWithoutResult(status -> {
            processor.ready(id, second.getUser().getId());
            throw new IllegalStateException("Test-only rollback");
        })).isInstanceOf(IllegalStateException.class);
        assertThat(battles.lock(id).getVersion()).isEqualTo(committed);
        assertThat(b.hasMessage(Duration.ofMillis(250))).isFalse();
        assertThat(a.hasMessage(Duration.ofMillis(250))).isFalse();
    }

    @Test void newGameplaySessionClosesOldAndLateDisconnectCannotRemoveReplacement() throws Exception {
        AuthDto first = register(), second = register();
        var old = connect(first, true);
        String oldId = sessions.target(first.getUser().getId()).orElseThrow().sessionId();
        UUID oldGeneration = sessions.current(first.getUser().getId()).orElseThrow().getSessionId();
        var replacement = connect(first, true);
        await().atMost(Duration.ofSeconds(5)).until(() -> !sessions.current(first.getUser().getId()).orElseThrow().getSessionId().equals(oldGeneration));
        old.await("ERROR"); old.closed.get(5, TimeUnit.SECONDS);
        sessions.closed(oldId);
        assertThat(sessions.current(first.getUser().getId())).isPresent();
        connect(second, true);
        UUID id = create(first, second);
        rest("POST", "/api/v1/battles/" + id + "/readiness", first, Map.of("ready", true), 200);
        replacement.event(item -> item.path("data").path("players").get(0).path("ready").asBoolean());
    }

    @Test void reconnectRestoresOwnAcceptedAnswerWithoutResettingRoundDeadline() throws Exception {
        AuthDto first = register(), second = register();
        var a = connect(first, true); var b = connect(second, true);
        UUID id = create(first, second); start(id, first, second);
        clock.set(START.plusSeconds(4));
        var saved = battles.lock(id);
        AnswerDto answer = answer(saved, true);
        rest("POST", "/api/v1/battles/" + id + "/answers", first, answer, 200);
        Instant originalDeadline = round(saved).getDeadline();
        a.close();
        await().atMost(Duration.ofSeconds(5)).until(() -> sessions.current(first.getUser().getId()).isEmpty());
        b.event(item -> !item.path("data").path("players").get(0).path("connected").asBoolean());
        clock.set(START.plusSeconds(10));
        var resumed = connect(first, true);
        resumed.event(item -> item.path("data").path("players").get(0).path("connected").asBoolean());
        JsonNode snapshot = rest("GET", "/api/v1/battles/" + id, first, null, 200);
        assertThat(snapshot.path("round").path("deadline").asText()).isEqualTo(originalDeadline.toString());
        assertThat(snapshot.path("round").path("mySelectedOptionId").asText()).isEqualTo(answer.getOptionId().toString());
        JsonNode replay = rest("POST", "/api/v1/battles/" + id + "/answers", first, answer, 200);
        assertThat(replay.path("acceptedAt").asText()).isEqualTo(START.plusSeconds(4).toString());
        assertThat(round(battles.lock(id)).getAnswers()).hasSize(1);
    }

    @Test void disconnectGraceAtEqualityFinalizesOnceWithoutStoppingQuestionClock() throws Exception {
        AuthDto first = register(), second = register();
        var a = connect(first, true); var b = connect(second, true);
        UUID id = create(first, second); start(id, first, second);
        clock.set(START.plusSeconds(4));
        a.close();
        await().atMost(Duration.ofSeconds(5)).until(() -> sessions.current(first.getUser().getId()).isEmpty());
        b.event(item -> !item.path("data").path("players").get(0).path("connected").asBoolean());
        clock.set(START.plusSeconds(34));
        processor.tick(id);
        var result = processor.result(id, first.getUser().getId());
        assertThat(result.getReason()).isEqualTo(CompletionReason.DISCONNECT);
        assertThat(result.getPlayers().getFirst().getRatingDelta()).isEqualTo(-16);
        b.event(item -> "FINISHED".equals(item.path("data").path("phase").asText()));
        processor.tick(id); processor.tick(id);
        assertThat(jdbc.queryForObject("select rating from ratings where user_id = ? and subject = 'MATH'", Integer.class, first.getUser().getId())).isEqualTo(984);
    }

    @Test void accessExpiryClosesRealSocketAndRestRefreshAllowsNewConnection() throws Exception {
        AuthDto user = register();
        var client = connect(user, true);
        String session = sessions.target(user.getUser().getId()).orElseThrow().sessionId();
        clock.set(START.plusSeconds(899));
        sessions.touch(session); sessions.expireDue();
        assertThat(client.closed.isDone()).isFalse();
        clock.set(START.plusSeconds(900));
        sessions.expireDue();
        assertThat(json.readTree(client.await("ERROR").body()).path("code").asText()).isEqualTo("UNAUTHORIZED");
        client.closed.get(5, TimeUnit.SECONDS);
        assertThat(sessions.current(user.getUser().getId())).isEmpty();
        JsonNode pair = request("POST", "/api/v1/auth/refresh", user.getTokens().getRefreshToken(), null, 200);
        var fresh = open(); fresh.connect(pair.path("accessToken").asText()); fresh.await("CONNECTED"); fresh.startHeartbeats();
        fresh.subscribe("/user/queue/events"); online(user);
        request("GET", "/api/v1/users/me", pair.path("accessToken").asText(), null, 200);
    }

    @Test void missingHeartbeatClosesConnectionAfterDetectionWindow() throws Exception {
        AuthDto user = register();
        var client = connect(user, true);
        client.stopHeartbeats();
        clock.set(START.plusSeconds(10));
        sessions.expireDue();
        client.await("ERROR"); client.closed.get(5, TimeUnit.SECONDS);
        assertThat(sessions.current(user.getUser().getId())).isEmpty();
        assertThat(sessions.lastDisconnectedAt(user.getUser().getId())).contains(START.plusSeconds(10));
    }

    @Test void jwtExpiryBeforeMonitorCannotReusePreviousDisconnectTimestamp() throws Exception {
        AuthDto first = register(), second = register();
        var a = connect(first, true); var b = connect(second, true);
        UUID id = create(first, second); start(id, first, second);
        clock.set(START.plusSeconds(4)); a.close();
        await().atMost(Duration.ofSeconds(5)).until(() -> sessions.current(first.getUser().getId()).isEmpty());
        b.event(item -> !item.path("data").path("players").get(0).path("connected").asBoolean());
        clock.set(START.plusSeconds(10));
        var claims = JwtClaimsSet.builder().issuer(jwtProperties.getIssuer()).subject(first.getUser().getId().toString())
                .audience(List.of("skillbattles-access")).issuedAt(START.plusSeconds(10)).expiresAt(START.plusSeconds(15))
                .claim("token_use", "access").id(UUID.randomUUID().toString()).build();
        var resumed = open();
        resumed.connect(encoder.encode(JwtEncoderParameters.from(JwsHeader.with(MacAlgorithm.HS256).build(), claims)).getTokenValue());
        resumed.await("CONNECTED"); resumed.startHeartbeats(); resumed.subscribe("/user/queue/events"); online(first);
        resumed.event(item -> item.path("data").path("players").get(0).path("connected").asBoolean());
        clock.set(START.plusSeconds(15));
        processor.tick(id);
        assertThat(battles.lock(id).getState().getPlayers().getFirst().getReconnectDeadline()).isEqualTo(START.plusSeconds(45));
        assertThat(sessions.observed(first.getUser().getId()).orElseThrow().getObservedAt()).isEqualTo(START.plusSeconds(15));
        sessions.expireDue();
        resumed.closed.get(5, TimeUnit.SECONDS);
    }

    private UUID create(AuthDto first, AuthDto second) {
        return processor.create(new CreateBattleDto(first.getUser().getId(), second.getUser().getId(), Subject.MATH, BattleMode.RANKED));
    }
    private void start(UUID id, AuthDto first, AuthDto second) throws Exception {
        rest("POST", "/api/v1/battles/" + id + "/readiness", first, Map.of("ready", true), 200);
        rest("POST", "/api/v1/battles/" + id + "/readiness", second, Map.of("ready", true), 200);
        clock.set(START.plusSeconds(3)); processor.tick(id);
    }

    private AuthDto register() {
        RegisterDto request = new RegisterDto();
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
