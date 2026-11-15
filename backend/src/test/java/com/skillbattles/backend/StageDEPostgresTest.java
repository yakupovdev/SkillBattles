package com.skillbattles.backend;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.skillbattles.backend.client.ResetMailClient;
import com.skillbattles.backend.dto.AuthDto;
import com.skillbattles.backend.dto.BattleDto;
import com.skillbattles.backend.dto.BattleRoundDto;
import com.skillbattles.backend.dto.CreateBattleDto;
import com.skillbattles.backend.dto.DuelDto;
import com.skillbattles.backend.dto.LeaderboardResponse;
import com.skillbattles.backend.dto.LoginDto;
import com.skillbattles.backend.dto.ProviderSubscriptionDto;
import com.skillbattles.backend.dto.QuestionImportDto;
import com.skillbattles.backend.dto.RegisterDto;
import com.skillbattles.backend.dto.RematchDto;
import com.skillbattles.backend.entity.ActivityType;
import com.skillbattles.backend.entity.BattleMode;
import com.skillbattles.backend.entity.BattlePhase;
import com.skillbattles.backend.exception.BusinessException;
import com.skillbattles.backend.exception.BusinessValidationException;
import com.skillbattles.backend.exception.ConflictException;
import com.skillbattles.backend.exception.GoneException;
import com.skillbattles.backend.exception.NotFoundException;
import com.skillbattles.backend.exception.UnauthorizedException;
import com.skillbattles.backend.processor.AuthProcessor;
import com.skillbattles.backend.processor.BattleProcessor;
import com.skillbattles.backend.processor.LeaderboardProcessor;
import com.skillbattles.backend.processor.MatchmakingProcessor;
import com.skillbattles.backend.processor.PasswordResetProcessor;
import com.skillbattles.backend.processor.RematchProcessor;
import com.skillbattles.backend.processor.RoundActionsProcessor;
import com.skillbattles.backend.processor.StatisticsProcessor;
import com.skillbattles.backend.service.BattleService;
import com.skillbattles.backend.service.MatchmakingRegistryService;
import com.skillbattles.backend.service.PasswordResetService;
import com.skillbattles.backend.service.QuestionImportFileService;
import com.skillbattles.backend.service.QuestionService;
import com.skillbattles.backend.service.SubscriptionService;
import com.skillbattles.backend.service.TokenService;
import com.skillbattles.backend.service.UserService;
import java.net.URI;
import java.net.http.HttpClient;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.TreeSet;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import org.assertj.core.api.Assertions;
import org.awaitility.Awaitility;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Primary;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

@SpringBootTest(
   webEnvironment = WebEnvironment.RANDOM_PORT,
   properties = {"app.jwt.secret=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=", "app.battle.scheduling.enabled=false", "app.matchmaking.scheduling.enabled=false", "app.season.scheduling.enabled=false", "app.realtime.monitor-ms=3600000"}
)
@AutoConfigureMockMvc
@Import({StageDEPostgresTest.Config.class})
@Testcontainers(
   disabledWithoutDocker = true
)
class StageDEPostgresTest {
   @Container
   static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:17.12-alpine");
   @Autowired
   MockMvc mvc;
   @Autowired
   ObjectMapper json;
   @Autowired
   JdbcTemplate jdbc;
   @Autowired
   AuthProcessor auth;
   @Autowired
   BattleProcessor processor;
   @Autowired
   BattleService battles;
   @Autowired
   UserService users;
   @Autowired
   MatchmakingProcessor matchmaking;
   @Autowired
   MatchmakingRegistryService registry;
   @Autowired
   RematchProcessor rematches;
   @Autowired
   RoundActionsProcessor actions;
   @Autowired
   SubscriptionService subscriptions;
   @Autowired
   StatisticsProcessor statistics;
   @Autowired
   QuestionService questions;
   @Autowired
   QuestionImportFileService files;
   @Autowired
   BattleFixtures.MutableClock clock;
   @Autowired
   BattleFixtures.TestPresence presence;
   @Autowired
   PasswordResetService resets;
   @Autowired
   PasswordResetProcessor resetProcessor;
   @Autowired
   TokenService tokens;
   @Autowired
   PlatformTransactionManager transactions;
   @Autowired
   LeaderboardProcessor leaderboard;
   @MockitoBean
   ResetMailClient mail;
   @LocalServerPort
   int port;
   final List<String> delivered = new CopyOnWriteArrayList<>();

   @DynamicPropertySource
   static void database(DynamicPropertyRegistry r) {
      PostgreSQLContainer var10002 = POSTGRES;
      Objects.requireNonNull(var10002);
      r.add("spring.datasource.url", var10002::getJdbcUrl);
      var10002 = POSTGRES;
      Objects.requireNonNull(var10002);
      r.add("spring.datasource.username", var10002::getUsername);
      var10002 = POSTGRES;
      Objects.requireNonNull(var10002);
      r.add("spring.datasource.password", var10002::getPassword);
   }

   @BeforeEach
   void setup() throws Exception {
      this.clock.set(BattleFixtures.START);
      this.presence.clear();
      this.delivered.clear();
      this.jdbc.execute("TRUNCATE question_reports,ranked_usage,battles,questions");
      BattleFixtures.uniformTiming(this.jdbc, 10);
      ArrayList<QuestionImportDto> bank = new ArrayList<>(this.files.read(Path.of(this.getClass().getResource("/fixtures/stage2-questions-test-only.json").toURI())));
      this.questions.importQuestions(bank, false);
      Mockito.when(this.mail.available()).thenReturn(true);
      ((ResetMailClient)Mockito.doAnswer((c) -> {
         this.delivered.add((String)c.getArgument(1));
         return null;
      }).when(this.mail)).send(Mockito.anyString(), Mockito.anyString());
   }

   @Test
   void registrationAgeScreenUsesEtAndNeverReturnsBirthData() throws Exception {
      HashMap<String, Object> payload = new HashMap<>(Map.of("email", "age-" + String.valueOf(UUID.randomUUID()) + "@example.com", "password", "ExamplePass123!", "nickname", "Age_" + this.suffix(), "birthYear", 2013, "birthMonth", 11));
      Assertions.assertThat(this.rest("POST", "/api/v1/auth/register", null, payload, 400).path("fieldErrors").get(0).path("field").asText()).isEqualTo("birthDay");
      payload.put("birthDay", 15);
      Assertions.assertThat(this.rest("POST", "/api/v1/auth/register", null, payload, 403).path("code").asText()).isEqualTo("AGE_RESTRICTED");
      payload.put("birthDay", 14);
      JsonNode body = this.rest("POST", "/api/v1/auth/register", null, payload, 201);
      Assertions.assertThat(body.toString()).doesNotContain(new CharSequence[]{"birthYear", "birthMonth", "birthDay", "passwordHash"});
   }

   @Test
   void profileValidatesPairsUniquenessAndRevokesAllRefreshWhileAccessSurvives() throws Exception {
      AuthDto a = this.register();
      AuthDto b = this.register();
      AuthDto second = this.auth.login(this.login(a));

      for(Map<? extends Object, ? extends Object> body : List.of(Map.of(), Map.of("newPassword", "NewPassword123!"), Map.of("currentPassword", "ExamplePass123!"), Map.of("email", "change@example.com"), Map.of("nickname", " "))) {
         this.rest("PATCH", "/api/v1/users/me", a, body, 400);
      }

      this.rest("PATCH", "/api/v1/users/me", a, Collections.singletonMap("nickname", null), 400);
      Assertions.assertThat(this.rest("PATCH", "/api/v1/users/me", a, Map.of("nickname", b.getUser().getNickname().toUpperCase(Locale.ROOT)), 409).path("code").asText()).isEqualTo("NICKNAME_ALREADY_EXISTS");
      this.rest("PATCH", "/api/v1/users/me", a, Map.of("currentPassword", "wrong", "newPassword", "NewPassword123!"), 401);
      JsonNode changed = this.rest("PATCH", "/api/v1/users/me", a, Map.of("nickname", "Renamed_" + this.suffix(), "currentPassword", "ExamplePass123!", "newPassword", "NewPassword123!"), 200);
      Assertions.assertThat(changed.path("passwordChanged").asBoolean()).isTrue();
      Assertions.assertThat(changed.path("reauthenticationRequired").asBoolean()).isTrue();

      for(AuthDto session : List.of(a, second)) {
         Assertions.assertThatThrownBy(() -> this.auth.refresh(session.getTokens().getRefreshToken())).isInstanceOf(UnauthorizedException.class);
      }

      this.rest("GET", "/api/v1/users/me", a, null, 200);
      LoginDto login = this.login(a);
      login.setPassword("NewPassword123!");
      Assertions.assertThat(this.auth.login(login)).isNotNull();
   }

   @Test
   void resetResponsePrivacyHashOnlySingleUseAndRefreshRevocation() throws Exception {
      AuthDto a = this.register();
      String email = a.getUser().getEmail();
      JsonNode known = this.rest("POST", "/api/v1/auth/password-reset/request", null, Map.of("email", email), 202);
      JsonNode unknown = this.rest("POST", "/api/v1/auth/password-reset/request", null, Map.of("email", String.valueOf(UUID.randomUUID()) + "@example.com"), 202);
      Assertions.assertThat(known).isEqualTo(unknown);
      Awaitility.await().atMost(Duration.ofSeconds(5L)).until(() -> this.delivered.size() == 1);
      String token = (String)this.delivered.getFirst();
      String hash = (String)this.jdbc.queryForObject("select token_hash from password_reset_tokens where user_id=?", String.class, new Object[]{this.id(a)});
      Assertions.assertThat(hash).isEqualTo(this.tokens.hash(token)).isNotEqualTo(token);
      Assertions.assertThat(known.toString()).doesNotContain(new CharSequence[]{token});
      this.rest("POST", "/api/v1/auth/password-reset/confirm", null, Map.of("token", token, "newPassword", "ResetPassword123!"), 204);
      Assertions.assertThat(this.rest("POST", "/api/v1/auth/password-reset/confirm", null, Map.of("token", token, "newPassword", "ResetPassword123!"), 400).path("code").asText()).isEqualTo("INVALID_RESET_TOKEN");
      Assertions.assertThatThrownBy(() -> this.auth.refresh(a.getTokens().getRefreshToken())).isInstanceOf(UnauthorizedException.class);
      this.rest("GET", "/api/v1/users/me", a, null, 200);
   }

   @Test
   void resetUnavailableAndRateLimitDoNotRevealAccountExistence() throws Exception {
      AuthDto a = this.register();
      Mockito.when(this.mail.available()).thenReturn(false);

      for(String email : List.of(a.getUser().getEmail(), String.valueOf(UUID.randomUUID()) + "@example.com")) {
         for(int i = 0; i < 4; ++i) {
            JsonNode response = this.rest("POST", "/api/v1/auth/password-reset/request", null, Map.of("email", email), i < 3 ? 503 : 429);
            Assertions.assertThat(response.path("code").asText()).isEqualTo(i < 3 ? "EMAIL_SERVICE_UNAVAILABLE" : "RATE_LIMITED");
         }
      }

      ((ResetMailClient)Mockito.verify(this.mail, Mockito.never())).send(Mockito.anyString(), Mockito.anyString());
   }

   @Test
   void resetRaceHasOneWinnerAndExpiryAtTwentyMinutes() throws Exception {
      AuthDto a = this.register();
      String raw = "isolated-test-reset-token-" + String.valueOf(UUID.randomUUID());
      this.resets.store(this.id(a), this.tokens.hash(raw));
      Assertions.assertThat(this.race(() -> this.confirmStatus(raw), () -> this.confirmStatus(raw))).containsExactlyInAnyOrder(new Integer[]{204, 400});
      String expired = "isolated-test-expired-token-" + String.valueOf(UUID.randomUUID());
      this.resets.store(this.id(a), this.tokens.hash(expired));
      this.clock.set(BattleFixtures.START.plusSeconds(1200L));
      Assertions.assertThatThrownBy(() -> this.resetProcessor.confirm(expired, "AnotherPassword123!", "test-expiry")).isInstanceOfSatisfying(BusinessException.class, (e) -> Assertions.assertThat(e.getCode()).isEqualTo("INVALID_RESET_TOKEN"));
   }

   @Test
   void statisticsUseAllHistoryAndAdvancedFieldsAreNullForFree() throws Exception {
      AuthDto a = this.register();
      AuthDto b = this.register();

      for(int i = 0; i < 12; ++i) {
         this.source(a, b, BattleMode.PRIVATE);
      }

      JsonNode free = this.rest("GET", "/api/v1/users/me/statistics", a, null, 200).path("disciplines").get(0);
      Assertions.assertThat(free.path("privateMatches").path("played").asInt()).isEqualTo(12);
      Assertions.assertThat(free.path("privateMatches").path("questionCount").asInt()).isEqualTo(12);
      Assertions.assertThat(free.path("privateMatches").path("accuracyPercent").asDouble()).isZero();
      Assertions.assertThat(free.path("topicStats").isNull()).isTrue();
      Assertions.assertThat(free.path("ratingHistory").isNull()).isTrue();
      this.grant(a);
      JsonNode pro = this.rest("GET", "/api/v1/users/me/statistics", a, null, 200).path("disciplines").get(0);
      Assertions.assertThat(pro.path("topicStats").size()).isPositive();
      Assertions.assertThat(pro.path("topicStats").get(0).path("isWeakTopic").asBoolean()).isTrue();
      Assertions.assertThat(pro.path("ratingHistory").isArray()).isTrue();
   }

   @Test
   void leaderboardDeterministicTiesCalibrationDeletedAndPending() throws Exception {
      AuthDto a = this.register();
      AuthDto b = this.register();
      AuthDto c = this.register();
      this.jdbc.update("UPDATE ratings SET rating=2000,rating_reached_at=? WHERE user_id IN (?,?) AND discipline_code='SAT_MATH'", new Object[]{Timestamp.from(BattleFixtures.START.minusSeconds(1L)), this.id(a), this.id(b)});
      this.jdbc.update("UPDATE ratings SET rating=2100 WHERE user_id=? AND discipline_code='SAT_MATH'", new Object[]{this.id(c)});
      this.auth.deleteUser(this.id(c));
      this.grant(a);
      JsonNode board = this.rest("GET", "/api/v1/leaderboards/SAT_MATH", a, null, 200);
      JsonNode top = board.path("top");
      List<String> ids = List.of(this.id(a).toString(), this.id(b).toString()).stream().sorted().toList();
      Assertions.assertThat(top.get(0).path("player").path("id").asText()).isEqualTo((String)ids.get(0));
      Assertions.assertThat(top.get(1).path("player").path("id").asText()).isEqualTo((String)ids.get(1));
      Assertions.assertThat(top.get(0).path("isCalibrating").asBoolean()).isTrue();
      Assertions.assertThat(board.toString()).doesNotContain(new CharSequence[]{"email", "birth", "customerId"});
      this.rest("GET", "/api/v1/leaderboards/UNKNOWN", a, null, 404);
      UUID live = this.processor.create(new CreateBattleDto(this.id(a), this.id(b), "SAT_MATH", BattleMode.RANKED));
      this.clock.set(Instant.parse("2027-01-01T05:00:00Z"));
      Assertions.assertThat(this.leaderboard.get("SAT_MATH", this.id(a)).getMe()).isNull();
      this.processor.surrender(live, this.id(a));
   }

   @Test
   void leaderboardReturnsSeparateMeBeyondTopFifty() {
      AuthDto me = this.register();

      for(int i = 0; i < 51; ++i) {
         AuthDto other = this.register();
         this.jdbc.update("UPDATE ratings SET rating=2000 WHERE user_id=? AND discipline_code='SAT_MATH'", new Object[]{this.id(other)});
      }

      LeaderboardResponse board = this.leaderboard.get("SAT_MATH", this.id(me));
      Assertions.assertThat(board.getTop()).hasSize(50);
      Assertions.assertThat(board.getMe().getPosition()).isGreaterThan(50L);
   }

   @Test
   void mistakesFilterAndReportsPreservePrivacyAndIdempotency() throws Exception {
      AuthDto a = this.register();
      AuthDto b = this.register();
      BattleDto s = this.source(a, b, BattleMode.PRIVATE);
      BattleRoundDto r = (BattleRoundDto)s.getState().getRounds().getFirst();
      String path = "/api/v1/battles/" + String.valueOf(s.getId());
      this.rest("GET", path + "/review?mistakesOnly=", a, null, 400);
      this.rest("GET", path + "/review?mistakesOnly=TRUE", a, null, 400);
      Assertions.assertThat(this.rest("GET", path + "/review?mistakesOnly=true", a, null, 403).path("code").asText()).isEqualTo("PRO_REQUIRED");
      String report = path + "/rounds/" + String.valueOf(r.getId()) + "/report";
      Map<String, String> payload = Map.of("reason", "OTHER", "comment", "TEST ONLY wording report");
      this.rest("POST", report, a, Map.of("reason", "OTHER"), 400);
      this.rest("POST", report, a, Map.of("reason", "TYPO", "comment", "x".repeat(1001)), 400);
      var nullComment=new HashMap<String,Object>();nullComment.put("reason","TYPO");nullComment.put("comment",null);this.rest("POST",report,a,nullComment,400);
      JsonNode first = this.rest("POST", report, a, payload, 201);
      Assertions.assertThat(this.rest("POST", report, a, payload, 200)).isEqualTo(first);
      this.rest("POST", report, a, Map.of("reason", "TYPO"), 409);
      this.rest("POST", report, this.register(), payload, 404);
      Assertions.assertThat(first.toString()).doesNotContain(new CharSequence[]{"correctOptionId", "explanation"});
      this.grant(a);
      JsonNode filtered = this.rest("GET", path + "/review?mistakesOnly=true", a, null, 200);
      Assertions.assertThat(filtered.path("mistakesOnly").asBoolean()).isTrue();
      Assertions.assertThat(filtered.path("rounds").size()).isEqualTo(1);
   }

   @Test
   void reportsRejectUnshownAndLiveUnrevealedRounds() throws Exception {
      AuthDto a = this.register();
      AuthDto b = this.register();
      UUID battle = this.create(a, b, BattleMode.PRIVATE);
      this.rest("GET","/api/v1/battles/"+battle+"/rematch",a,null,404);this.rest("POST","/api/v1/battles/"+battle+"/rematch",a,null,409);this.rest("DELETE","/api/v1/battles/"+battle+"/rematch",a,null,404);
      this.start(battle, a, b);
      BattleDto snapshot = this.battles.getForParticipant(battle, this.id(a));
      String path = "/api/v1/battles/" + String.valueOf(battle) + "/rounds/";
      this.rest("POST", path + String.valueOf(((BattleRoundDto)snapshot.getState().getRounds().getFirst()).getId()) + "/report", a, Map.of("reason", "TYPO"), 409);
      this.rest("POST", path + String.valueOf(((BattleRoundDto)snapshot.getState().getRounds().get(1)).getId()) + "/report", a, Map.of("reason", "TYPO"), 404);
   }

   @Test
   void rematchRepeatedConsentDoesNotExtendAndDoubleConsentCreatesOneBattle() throws Exception {
      AuthDto a = this.register();
      AuthDto b = this.register();
      BattleDto source = this.source(a, b, BattleMode.PRIVATE);
      String path = "/api/v1/battles/" + String.valueOf(source.getId()) + "/rematch";
      this.rest("GET", path, a, null, 404);
      JsonNode first = this.rest("POST", path, a, null, 200);
      this.clock.set(this.clock.instant().plusSeconds(5L));
      Assertions.assertThat(this.rest("POST", path, a, null, 200)).isEqualTo(first);
      JsonNode activity = this.rest("GET", "/api/v1/users/me/activity", a, null, 200);
      Assertions.assertThat(activity.path("resourceKind").asText()).isEqualTo("REMATCH");
      Assertions.assertThat(activity.path("resourceId").asText()).isEqualTo(source.getId().toString());
      List<UUID> responses = this.<UUID>race(() -> this.rematches.request(source.getId(), this.id(b)).getBattleId(), () -> this.rematches.request(source.getId(), this.id(b)).getBattleId());
      Assertions.assertThat((UUID)responses.get(0)).isEqualTo(responses.get(1));
      UUID next = (UUID)responses.getFirst();
      BattleDto battle = this.battles.getForParticipant(next, this.id(a));
      Assertions.assertThat(battle.getPhase()).isEqualTo(BattlePhase.WAITING_READY);
      Assertions.assertThat(battle.getState().getPlayers()).allMatch((p) -> !p.isReady());
      Assertions.assertThat(next).isNotEqualTo(source.getId());
      this.rest("DELETE", path, a, null, 409);
   }

   @Test
   void rematchExpiryCancellationAndActivityRacesReleaseReservations() throws Exception {
      AuthDto a = this.register();
      AuthDto b = this.register();
      BattleDto s = this.source(a, b, BattleMode.PRIVATE);
      RematchDto first = this.rematches.request(s.getId(), this.id(a));
      Assertions.assertThatThrownBy(() -> this.matchmaking.search(this.id(a), "SAT_MATH")).isInstanceOf(ConflictException.class);
      this.clock.set(first.getExpiresAt());
      Assertions.assertThat(this.rematches.get(s.getId(), this.id(a)).getStatus()).isEqualTo("EXPIRED");
      Assertions.assertThat(this.matchmaking.activity(this.id(a)).getType()).isEqualTo(ActivityType.NONE);
      Assertions.assertThatThrownBy(() -> this.rematches.request(s.getId(), this.id(b))).isInstanceOf(GoneException.class);
      DuelDto room = this.matchmaking.createDuel(this.id(a), "SAT_MATH");
      this.matchmaking.cancelDuel(this.id(a), room.getId());
      BattleDto other = this.source(a, b, BattleMode.PRIVATE);
      this.rematches.request(other.getId(), this.id(a));
      this.rematches.cancel(other.getId(), this.id(b));
      this.rematches.cancel(other.getId(), this.id(b));
      Assertions.assertThat(this.matchmaking.activity(this.id(a)).getType()).isEqualTo(ActivityType.NONE);
      BattleDto third = this.source(a, b, BattleMode.PRIVATE);
      List<Integer> statuses = this.<Integer>race(() -> {
         try {
            this.rematches.request(third.getId(), this.id(a));
            return 200;
         } catch (ConflictException var4) {
            return 409;
         }
      }, () -> {
         try {
            this.matchmaking.createDuel(this.id(a), "SAT_MATH");
            return 200;
         } catch (ConflictException var3) {
            return 409;
         }
      });
   }

   @Test
   void rematchRollbackDoesNotPublishOrReserve() {
      AuthDto a = this.register();
      AuthDto b = this.register();
      BattleDto s = this.source(a, b, BattleMode.PRIVATE);
      (new TransactionTemplate(this.transactions)).executeWithoutResult((tx) -> {
         this.rematches.request(s.getId(), this.id(a));
         tx.setRollbackOnly();
      });
      Assertions.assertThatThrownBy(() -> this.rematches.get(s.getId(), this.id(a))).isInstanceOf(NotFoundException.class);
      Assertions.assertThat(this.matchmaking.activity(this.id(a)).getType()).isEqualTo(ActivityType.NONE);
   }

   @Test
   void mistakesKeepTimeoutAndIncompleteWrongButExcludeCorrect() throws Exception {
      AuthDto a = this.register();
      AuthDto b = this.register();
      this.grant(a);
      UUID battle = this.create(a, b, BattleMode.PRIVATE);
      this.start(battle, a, b);
      BattleDto first = this.battles.getForParticipant(battle, this.id(a));
      this.processor.answer(battle, this.id(a), BattleFixtures.answer(first, true), this.clock.instant());
      this.processor.answer(battle, this.id(b), BattleFixtures.answer(first, false), this.clock.instant());
      this.clock.set(BattleFixtures.round(this.battles.getForParticipant(battle, this.id(a))).getRevealEndsAt());
      this.processor.tick(battle);
      BattleDto second = this.battles.getForParticipant(battle, this.id(a));
      UUID timeout = BattleFixtures.round(second).getId();
      this.processor.answer(battle, this.id(b), BattleFixtures.answer(second, true), this.clock.instant());
      this.clock.set(BattleFixtures.round(second).getDeadline());
      this.processor.tick(battle);
      this.clock.set(BattleFixtures.round(this.battles.getForParticipant(battle, this.id(a))).getRevealEndsAt());
      this.processor.tick(battle);
      BattleDto third = this.battles.getForParticipant(battle, this.id(a));
      UUID wrong = BattleFixtures.round(third).getId();
      this.processor.answer(battle, this.id(a), BattleFixtures.answer(third, false), this.clock.instant());
      this.processor.surrender(battle, this.id(b));
      JsonNode filtered = this.rest("GET", "/api/v1/battles/" + String.valueOf(battle) + "/review?mistakesOnly=true", a, null, 200);
      Assertions.assertThat(filtered.path("rounds").findValuesAsText("roundId")).containsExactly(new String[]{timeout.toString(), wrong.toString()});
   }

   @Test
   void reportsAndRematchesPreserveOwnerAndOldHistoryGates() throws Exception {
      AuthDto a = this.register();
      AuthDto b = this.register();
      AuthDto outsider = this.register();
      BattleDto s = this.source(a, b, BattleMode.PRIVATE);
      BattleRoundDto round = (BattleRoundDto)s.getState().getRounds().getFirst();
      String root = "/api/v1/battles/" + String.valueOf(s.getId());
      this.rest("POST",root+"/rounds/"+round.getId()+"/report",outsider,Map.of("reason","TYPO"),404);
      this.rest("GET",root+"/rematch",outsider,null,404);
      this.grant(a);

      for(int i = 0; i < 11; ++i) {
         UUID id = this.create(a, b, BattleMode.PRIVATE);
         this.processor.surrender(id, this.id(a));
         this.clock.set(this.clock.instant().plusSeconds(1L));
      }

      this.jdbc.update("UPDATE subscription_accounts SET paid=false,pro_active=false WHERE user_id=?", new Object[]{this.id(a)});

      for(String path : List.of(root + "/review", root + "/rematch")) {
         Assertions.assertThat(this.rest("GET", path, a, null, 403).path("code").asText()).isEqualTo("HISTORY_ACCESS_REQUIRED");
      }

      this.rest("POST", root + "/rematch", a, null, 403);
      this.rest("POST", root + "/rounds/" + String.valueOf(round.getId()) + "/report", a, Map.of("reason", "TYPO"), 403);
   }

   @Test
   void concurrentReportsReturnTheSameReportWithOneCreation() throws Exception {
      AuthDto a = this.register();
      AuthDto b = this.register();
      BattleDto s = this.source(a, b, BattleMode.PRIVATE);
      BattleRoundDto r = (BattleRoundDto)s.getState().getRounds().getFirst();
      Assertions.assertThat(this.race(() -> this.actions.report(s.getId(), r.getId(), this.id(a), "TYPO", (String)null).isCreated(), () -> this.actions.report(s.getId(), r.getId(), this.id(a), "TYPO", (String)null).isCreated())).containsExactlyInAnyOrder(new Boolean[]{true, false});
   }

 @Test void rematchRealStompEnvelopeReachesBothParticipantsAfterCommit() throws Exception {
  var a=register();var b=register();var s=source(a,b,BattleMode.PRIVATE);
  try(var http=HttpClient.newHttpClient();var ca=connect(http,a);var cb=connect(http,b)){
   var r=rematches.request(s.getId(),id(a));
   for(var client:List.of(ca,cb)){var event=client.event(item->item.path("type").asText().equals("REMATCH_CHANGED"));Assertions.assertThat(event.path("resourceId").asText()).isEqualTo(s.getId().toString());Assertions.assertThat(event.path("version").asInt()).isEqualTo(r.getVersion());Assertions.assertThat(event.path("data").path("requestedBy").get(0).asText()).isEqualTo(id(a).toString());Assertions.assertThat(event.toString()).doesNotContain("email","birth","participants");}
  }
 }
 @Test void retiredRoutesAndEntitlementAreAbsent()throws Exception{
  var a=register();UUID battle=UUID.randomUUID(),round=UUID.randomUUID(),session=UUID.randomUUID();
  rest("POST","/api/v1/battles/"+battle+"/rounds/"+round+"/practice",a,Map.of(),404);
  rest("GET","/api/v1/practice-sessions/"+session,a,null,404);
  rest("POST","/api/v1/practice-sessions/"+session+"/answers",a,Map.of(),404);
  var schema=rest("GET","/v3/api-docs",null,null,200);
  Assertions.assertThat(schema.toString()).doesNotContain("/practice","canPracticeSimilar","PracticeSession","PracticeResult","NO_SIMILAR_QUESTION","PRACTICE_");
  for(var caller:List.of(a,register())){
   for(String path:List.of("/api/v1/users/me/statistics","/api/v1/users/me/limits","/api/v1/subscriptions/me"))Assertions.assertThat(rest("GET",path,caller,null,200).toString()).doesNotContain("canPracticeSimilar");
   grant(caller);Assertions.assertThat(rest("GET","/api/v1/subscriptions/me",caller,null,200).path("entitlements").path("canFilterMistakes").asBoolean()).isTrue();
   Assertions.assertThat(rest("GET","/api/v1/subscriptions/me",caller,null,200).toString()).doesNotContain("canPracticeSimilar");
  }
  var plans=rest("GET","/api/v1/subscriptions/plans",null,null,200);Assertions.assertThat(plans.toString().toLowerCase(Locale.ROOT)).doesNotContain("similar practice");
  Assertions.assertThat(plans.get(1).path("amountCents").asInt()).isEqualTo(799);Assertions.assertThat(plans.get(2).path("amountCents").asInt()).isEqualTo(4799);
  Assertions.assertThat(jdbc.queryForObject("select to_regclass('public.practice_sessions')::text",String.class)).isNull();
 }
 @Test void migrationRemovesOnlyPracticeDataAndPreservesReportsAndBattles(){
  var a=register();var b=register();var source=source(a,b,BattleMode.PRIVATE);var round=source.getState().getRounds().getFirst();
  var report=actions.report(source.getId(),round.getId(),id(a),"TYPO",null);String schema="retired_practice_upgrade";
  var v10=org.flywaydb.core.Flyway.configure().dataSource(POSTGRES.getJdbcUrl(),POSTGRES.getUsername(),POSTGRES.getPassword()).schemas(schema).target("10").load();v10.migrate();
  jdbc.update("insert into retired_practice_upgrade.users select * from public.users where id in (?,?)",id(a),id(b));
  jdbc.update("insert into retired_practice_upgrade.battles select * from public.battles where id=?",source.getId());
  jdbc.update("insert into retired_practice_upgrade.question_reports select * from public.question_reports where id=?",report.getId());
  jdbc.update("insert into retired_practice_upgrade.practice_sessions(id,created_at,updated_at,user_id,source_battle_id,source_round_id,discipline_code,expires_at,question) values (?,now(),now(),?,?,?,'SAT_MATH',now()+interval '30 minutes','{}'::jsonb)",UUID.randomUUID(),id(a),source.getId(),round.getId());
  org.flywaydb.core.Flyway.configure().dataSource(POSTGRES.getJdbcUrl(),POSTGRES.getUsername(),POSTGRES.getPassword()).schemas(schema).target("11").load().migrate();
  Assertions.assertThat(jdbc.queryForObject("select to_regclass('retired_practice_upgrade.practice_sessions')::text",String.class)).isNull();
  Assertions.assertThat(jdbc.queryForObject("select count(*) from retired_practice_upgrade.users",Integer.class)).isEqualTo(2);
  Assertions.assertThat(jdbc.queryForObject("select count(*) from retired_practice_upgrade.battles",Integer.class)).isEqualTo(1);
  Assertions.assertThat(jdbc.queryForObject("select id from retired_practice_upgrade.question_reports",UUID.class)).isEqualTo(report.getId());
  Assertions.assertThat(jdbc.queryForObject("select result::text from retired_practice_upgrade.battles",String.class)).isEqualTo(jdbc.queryForObject("select result::text from public.battles where id=?",String.class,source.getId()));
 }
 @Test void allFortyRestOperationsMatchTargetResponseAndRequestShapes()throws Exception{
  var actual=rest("GET","/v3/api-docs",null,null,200);Files.writeString(Path.of("target/generated-openapi.json"),actual.toPrettyString());
  var expected=json.readTree(getClass().getResourceAsStream("/contracts/v03-shapes.json"));
  var found=new TreeSet<String>();actual.path("paths").fields().forEachRemaining(p->p.getValue().fieldNames().forEachRemaining(m->{if(Set.of("get","post","patch","delete").contains(m))found.add(m.toUpperCase()+" "+p.getKey());}));
  var target=new TreeSet<String>();expected.fieldNames().forEachRemaining(target::add);Assertions.assertThat(found).isEqualTo(target).hasSize(40);
  var failures=new ArrayList<String>();
  expected.fields().forEachRemaining(e->{String[] key=e.getKey().split(" ",2);var operation=actual.path("paths").path(key[1]).path(key[0].toLowerCase(Locale.ROOT));
   e.getValue().path("success").fields().forEachRemaining(response->{var generated=operation.path("responses").path(response.getKey());if(generated.isMissingNode())failures.add(e.getKey()+" missing success "+response.getKey());else compareShape(response.getValue(),schema(generated),actual,e.getKey()+" response "+response.getKey(),failures);});
   e.getValue().path("errors").fields().forEachRemaining(error->{var response=operation.path("responses").path(error.getKey());if(response.isMissingNode())failures.add(e.getKey()+" missing error status "+error.getKey());else {var errorSchema=resolve(schema(response),actual);var fields=new TreeSet<String>();errorSchema.path("properties").fieldNames().forEachRemaining(fields::add);if(!fields.equals(Set.of("code","message","fieldErrors","resetsAt")))failures.add(e.getKey()+" error "+error.getKey()+" lacks ErrorResponse");}});
   compareShape(e.getValue().path("request"),schema(operation.path("requestBody")),actual,e.getKey()+" request",failures);
  });Assertions.assertThat(failures).isEmpty();
 }
 JsonNode schema(JsonNode container){var values=container.path("content").elements();return values.hasNext()?values.next().path("schema"):json.createObjectNode();}
 JsonNode resolve(JsonNode schema,JsonNode doc){if(schema.has("$ref"))return resolve(doc.at(schema.path("$ref").asText().substring(1)),doc);if(schema.has("allOf")){var merged=json.createObjectNode();for(var item:schema.path("allOf"))merged.setAll((ObjectNode)resolve(item,doc));return merged;}return schema;}
 String schemaType(JsonNode node){var type=node.path("type");if(type.isArray())for(var t:type)if(!t.asText().equals("null"))return t.asText();return type.asText("object");}
 void compareShape(JsonNode expected,JsonNode raw,JsonNode doc,String at,List<String> failures){
  JsonNode actual=resolve(raw,doc);
  if(expected.has("$type")){if(!raw.isEmpty()&&!expected.path("$type").asText().equals(schemaType(actual)))failures.add(at+" type expected "+expected+" got "+actual);return;}
  if(expected.has("[]")){if(!schemaType(actual).equals("array")){failures.add(at+" expected array");return;}compareShape(expected.path("[]"),actual.path("items"),doc,at+"[]",failures);return;}
  var fields=new TreeSet<String>();actual.path("properties").fieldNames().forEachRemaining(fields::add);var want=new TreeSet<String>();expected.fieldNames().forEachRemaining(want::add);
  if(!fields.equals(want)){failures.add(at+" fields expected "+want+" got "+fields);return;}
  expected.fields().forEachRemaining(e->compareShape(e.getValue(),actual.path("properties").path(e.getKey()),doc,at+"."+e.getKey(),failures));
 }
 NativeStompClient connect(HttpClient http,AuthDto a)throws Exception{var c=new NativeStompClient(http,URI.create("ws://localhost:"+port+"/ws/v1/events"),"http://localhost:"+port,json);c.connect(a.getTokens().getAccessToken());c.await("CONNECTED");c.startHeartbeats();c.subscribe("/user/queue/events");return c;}
 JsonNode rest(String method,String path,AuthDto a,Object body,int expected)throws Exception{
  var request=MockMvcRequestBuilders.request(HttpMethod.valueOf(method),path);if(a!=null)request.header("Authorization","Bearer "+a.getTokens().getAccessToken());if(body!=null)request.contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsBytes(body));
  var response=mvc.perform(request).andReturn().getResponse();Assertions.assertThat(response.getStatus()).as(method+" "+path+" "+response.getContentAsString()).isEqualTo(expected);return response.getContentAsByteArray().length==0?json.nullNode():json.readTree(response.getContentAsByteArray());
 }
 int confirmStatus(String raw){try{resetProcessor.confirm(raw,"ResetPassword123!","test-race");return 204;}catch(BusinessValidationException ex){return 400;}}
 <T> List<T> race(Callable<T> a,Callable<T> b)throws Exception{var gate=new CountDownLatch(1);try(var executor=Executors.newFixedThreadPool(2)){var f=executor.submit(()->{gate.await();return a.call();});var g=executor.submit(()->{gate.await();return b.call();});gate.countDown();return List.of(f.get(20,TimeUnit.SECONDS),g.get(20,TimeUnit.SECONDS));}}
 AuthDto register(){var r=new RegisterDto();r.setBirthYear(2000);r.setBirthMonth(1);r.setEmail(suffix()+"@example.com");r.setNickname("DE_"+suffix());r.setPassword("ExamplePass123!");return auth.register(r);}
 String suffix(){return UUID.randomUUID().toString().replace("-","").substring(0,12);}
 UUID id(AuthDto a){return a.getUser().getId();}
 LoginDto login(AuthDto a){var d=new LoginDto();d.setEmail(a.getUser().getEmail());d.setPassword("ExamplePass123!");return d;}
 UUID create(AuthDto a,AuthDto b,BattleMode mode){return processor.create(new CreateBattleDto(id(a),id(b),"SAT_MATH",mode));}
 void start(UUID battle,AuthDto a,AuthDto b){presence.connect(id(a),clock.instant());presence.connect(id(b),clock.instant());processor.ready(battle,id(a));processor.ready(battle,id(b));clock.set(clock.instant().plusSeconds(3));processor.tick(battle);}
 BattleDto source(AuthDto a,AuthDto b,BattleMode mode){UUID battle=create(a,b,mode);start(battle,a,b);var state=battles.getForParticipant(battle,id(a));processor.answer(battle,id(a),BattleFixtures.answer(state,false),clock.instant());processor.surrender(battle,id(b));clock.set(clock.instant().plusSeconds(1));return battles.getForParticipant(battle,id(a));}
 void grant(AuthDto a){String customer="cus_fixture_"+id(a);subscriptions.bindCustomer(id(a),customer);var p=new ProviderSubscriptionDto(customer,"sub_fixture_"+id(a),"price_fixture","ACTIVE",BattleFixtures.START.minusSeconds(1),BattleFixtures.START.plusSeconds(86400),false,true,false);subscriptions.apply(id(a),"evt_fixture_"+UUID.randomUUID(),p,"PRO_MONTHLY");}
 @TestConfiguration static class Config {
  @Bean @Primary BattleFixtures.MutableClock testClock(){return new BattleFixtures.MutableClock();}
  @Bean @Primary BattleFixtures.TestPresence presence(){return new BattleFixtures.TestPresence();}
 }
}
