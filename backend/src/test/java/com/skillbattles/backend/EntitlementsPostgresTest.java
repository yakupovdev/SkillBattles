package com.skillbattles.backend;

import com.fasterxml.jackson.databind.*;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.processor.*;
import com.skillbattles.backend.service.*;
import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.*;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.context.annotation.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.*;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.*;
import java.time.*;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.*;
import static com.skillbattles.backend.BattleFixtures.*;
import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties={"app.jwt.secret=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=","app.battle.scheduling.enabled=false","app.matchmaking.scheduling.enabled=false"})
@AutoConfigureMockMvc @Import(EntitlementsPostgresTest.Config.class) @Testcontainers(disabledWithoutDocker=true)
class EntitlementsPostgresTest {
    @Container static final PostgreSQLContainer<?> POSTGRES=new PostgreSQLContainer<>("postgres:17.12-alpine");
    @DynamicPropertySource static void database(DynamicPropertyRegistry r){r.add("spring.datasource.url",POSTGRES::getJdbcUrl);r.add("spring.datasource.username",POSTGRES::getUsername);r.add("spring.datasource.password",POSTGRES::getPassword);}
    @TestConfiguration static class Config {
        @Bean @Primary MutableClock testClock(){return new MutableClock();}
        @Bean @Primary TestPresence testPresence(){return new TestPresence();}
        @Bean Notifications notifications(){return new Notifications();}
    }
    static class Notifications {final List<AccountChangedEvent> values=new CopyOnWriteArrayList<>();@org.springframework.context.event.EventListener public void event(AccountChangedEvent e){values.add(e);}}
    @Autowired MutableClock clock;@Autowired TestPresence presence;@Autowired AuthProcessor auth;
    @Autowired SubscriptionService subscriptions;@Autowired UsageProcessor limits;@Autowired UsageService usage;
    @Autowired StreakService streaks;@Autowired BattleAccessProcessor access;@Autowired BattleProcessor processor;@Autowired BattleService battles;
    @Autowired MatchmakingProcessor matchmaking;@Autowired QuestionImportProcessor imports;@Autowired QuestionImportFileService files;
    @Autowired JdbcTemplate jdbc;@Autowired MockMvc mvc;@Autowired ObjectMapper json;@Autowired PlatformTransactionManager tx;
    @Autowired Notifications notifications;
    @BeforeEach void setup() throws Exception {
        clock.set(START);presence.clear();notifications.values.clear();jdbc.execute("TRUNCATE question_reports,ranked_usage,battles,questions");uniformTiming(jdbc,10);
        imports.importQuestions(files.read(Path.of(Objects.requireNonNull(getClass().getResource("/fixtures/stage2-questions-test-only.json")).toURI())),false);
    }
    @Test void registrationGrantsPermanentProAcrossProfileRightsAndMoreThanFiveRankedGames() throws Exception {
        var a=registerPro();
        assertThat(a.getUser().isPro()).isTrue();
        for(int i=0;i<6;i++){var b=registerPro();UUID battle=create(a,b,"SAT_MATH",BattleMode.RANKED);start(battle,a,b);processor.surrender(battle,id(b));}
        assertThat(limits.limits(id(a)).isCanStartRanked()).isTrue();
        assertThat(limits.limits(id(a)).getFreeRankedRemaining()).isNull();
        int version=subscriptions.entitlements(id(a)).getVersion();
        clock.set(clock.instant().plus(Duration.ofDays(3660)));
        assertThat(subscriptions.entitlements(id(a)).isPro()).isTrue();
        assertThat(subscriptions.entitlements(id(a)).getVersion()).isEqualTo(version);
        var current=subscriptions.current(id(a));
        assertThat(current.getPlanCode()).isEqualTo("PRO");
        assertThat(current.getBillingMode()).isEqualTo("NONE");
        assertThat(current.getCurrentPeriodEnd()).isNull();
        // Use a fresh token after the clock jump.
        var refreshed=auth.login(login(a));
        mvc.perform(get("/api/v1/subscriptions/me").header("Authorization",bearer(refreshed)))
            .andExpect(status().isOk()).andExpect(jsonPath("$.entitlements.isPro").value(true));
        mvc.perform(get("/api/v1/users/me").header("Authorization",bearer(refreshed)))
            .andExpect(status().isOk()).andExpect(jsonPath("$.isPro").value(true));
    }
    @Test void removedPaymentRoutesAndProviderSecuritySchemeAreAbsent() throws Exception {
        var a=registerPro();
        mvc.perform(get("/api/v1/subscriptions/plans").header("Authorization",bearer(a))).andExpect(status().isNotFound());
        for(String route:List.of("checkout","portal","webhook"))
            mvc.perform(post("/api/v1/subscriptions/"+route).header("Authorization",bearer(a)).contentType("application/json").content("{}"))
                .andExpect(status().isNotFound());
        var api=json.readTree(mvc.perform(get("/v3/api-docs")).andExpect(status().isOk()).andReturn().getResponse().getContentAsString());
        assertThat(api.path("paths").has("/api/v1/subscriptions/me")).isTrue();
        for(String route:List.of("plans","checkout","portal","webhook"))assertThat(api.path("paths").has("/api/v1/subscriptions/"+route)).isFalse();
        assertThat(api.path("components").path("securitySchemes").has("stripeSignature")).isFalse();
    }
    @Test void loginAndRefreshDoNotUpgradeExistingFreeAccounts() {
        var a=register();
        assertThat(auth.login(login(a)).getUser().isPro()).isFalse();
        assertThat(auth.refresh(a.getTokens().getRefreshToken()).getUser().isPro()).isFalse();
        assertThat(subscriptions.entitlements(id(a)).isPro()).isFalse();
    }
    LoginDto login(AuthDto a){var login=new LoginDto();login.setEmail(a.getUser().getEmail());login.setPassword("ExamplePass123!");return login;}
    @Test void quotaChargesFirstQuestionAcrossDisciplinesAndRefundsOnlyOriginalDayOnce() throws Exception {
        var a=register();var b=register();UUID battle=create(a,b,"SAT_MATH",BattleMode.RANKED);
        assertThat(limits.limits(id(a)).getRankedStartedToday()).isZero();start(battle,a,b);
        assertThat(limits.limits(id(a)).getRankedStartedToday()).isEqualTo(1);processor.tick(battle);assertThat(limits.limits(id(a)).getRankedStartedToday()).isEqualTo(1);
        var oldDay=EtCalendar.date(clock.instant());clock.set(clock.instant().plus(Duration.ofDays(1)));processor.interrupt(battle);processor.interrupt(battle);
        assertThat(usage.used(id(a),oldDay)).isZero();assertThat(limits.limits(id(a)).getRankedStartedToday()).isZero();
        for(int i=0;i<5;i++){var other=register();battle=create(a,other,i%2==0?"SAT_MATH":"SAT_RW",BattleMode.RANKED);start(battle,a,other);processor.surrender(battle,id(a));}
        assertThat(limits.limits(id(a)).getRankedStartedToday()).isEqualTo(5);
        var refreshed=auth.refresh(a.getTokens().getRefreshToken());
        mvc.perform(post("/api/v1/matchmaking/entries").header("Authorization",bearer(refreshed)).contentType("application/json").content("{\"disciplineCode\":\"SAT_MATH\",\"format\":\"STANDARD\"}"))
                .andExpect(status().isTooManyRequests()).andExpect(jsonPath("$.code").value("DAILY_LIMIT_REACHED")).andExpect(jsonPath("$.resetsAt").exists()).andExpect(header().exists("Retry-After"));
        var other=register();battle=create(a,other,"SAT_MATH",BattleMode.PRIVATE);start(battle,a,other);processor.surrender(battle,id(other));assertThat(limits.limits(id(a)).getRankedStartedToday()).isEqualTo(5);
    }
    @Test void downgradeBetweenReadyAndFirstQuestionCancelsBothWithoutPartialUsage() throws Exception {
        var a=register();var b=register();grant(a);
        for(int i=0;i<5;i++){var other=register();UUID old=create(a,other,"SAT_MATH",BattleMode.RANKED);start(old,a,other);processor.surrender(old,id(a));}
        UUID battle=create(a,b,"SAT_MATH",BattleMode.RANKED);processor.ready(battle,id(a));processor.ready(battle,id(b));
        setPro(a,false);
        clock.set(clock.instant().plusSeconds(3));processor.tick(battle);
        assertThat(processor.result(battle,id(a)).getReason()).isEqualTo(CompletionReason.QUOTA_EXHAUSTED);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM ranked_usage WHERE battle_id=?",Integer.class,battle)).isZero();
        assertThat(matchmaking.activity(id(a)).getType()).isEqualTo(ActivityType.NONE);assertThat(limits.limits(id(b)).getRankedStartedToday()).isZero();
    }
    @Test void rollbackAfterStartOrSettlementLeavesNoUsageStreakOrAccountEventsCommitted() {
        var a=register();var b=register();UUID battle=create(a,b,"SAT_MATH",BattleMode.RANKED);processor.ready(battle,id(a));processor.ready(battle,id(b));clock.set(clock.instant().plusSeconds(3));
        var transaction=new TransactionTemplate(tx);
        assertThatThrownBy(() -> transaction.execute(status -> {processor.tick(battle);throw new IllegalStateException("Test-only rollback");})).isInstanceOf(IllegalStateException.class);
        assertThat(limits.limits(id(a)).getRankedStartedToday()).isZero();assertThat(notifications.values).isEmpty();processor.tick(battle);notifications.values.clear();
        assertThatThrownBy(() -> transaction.execute(status -> {processor.surrender(battle,id(b));throw new IllegalStateException("Test-only rollback");})).isInstanceOf(IllegalStateException.class);
        assertThat(streaks.current(id(a)).getLastQualifiedDate()).isNull();assertThat(battles.lock(battle).getPhase()).isEqualTo(BattlePhase.QUESTION);assertThat(notifications.values).isEmpty();
        processor.surrender(battle,id(b));assertThat(streaks.current(id(a)).getDailyCurrent()).isEqualTo(1);assertThat(streaks.current(id(b)).getDailyCurrent()).isZero();
        int count=notifications.values.size();processor.tick(battle);processor.surrender(battle,id(b));assertThat(notifications.values).hasSize(count);
    }
    @Test void freeRedactionUpgradeAndDowngradePreserveRawAnswersWithoutChangingBattleVersion() throws Exception {
        var a=register();var b=register();UUID battle=create(a,b,"SAT_MATH",BattleMode.PRIVATE);start(battle,a,b);
        var raw=battles.lock(battle);var answer=answer(raw,true);processor.answer(battle,id(a),answer,clock.instant());
        var hidden=processor.snapshot(battle,id(b));assertThat(hidden.getRound().getReveal()).isNull();assertThat(hidden.getRound().getMySelectedOptionId()).isNull();
        processor.answer(battle,id(b),answer(raw,false),clock.instant());var free=processor.snapshot(battle,id(a));
        assertThat(free.getRound().getReveal().getCorrectOptionId()).isNull();assertThat(free.getRound().getReveal().getAnswers().get(1).getSelectedOptionId()).isNull();
        int version=free.getVersion();grant(a);var pro=processor.snapshot(battle,id(a));assertThat(pro.getVersion()).isEqualTo(version);
        assertThat(pro.getRound().getReveal().getCorrectOptionId()).isEqualTo(answer.getOptionId());assertThat(pro.getRound().getReveal().getAnswers().get(1).getSelectedOptionId()).isNotNull();
        setPro(a,false);
        assertThat(processor.snapshot(battle,id(a)).getRound().getReveal().getCorrectOptionId()).isNull();
        processor.surrender(battle,id(b));var review=processor.review(battle,id(a));assertThat(review.getRounds().getFirst().getQuestion().getExplanation()).isNull();
        assertThat(battles.lock(battle).getState().getRounds().getFirst().getQuestion().getExplanation()).isNotBlank();
        assertThat(processor.surrender(battle,id(a)).getRound().getReveal().getCorrectOptionId()).isNull();
    }
    @Test void latestTenAreChosenBeforeFiltersAndAllDirectHistoricalRoutesAreProtected() throws Exception {
        var a=register();var b=register();List<UUID> ids=new ArrayList<>();
        for(int i=0;i<12;i++){clock.set(START.plusSeconds(i*10));UUID battle=create(a,b,i<2?"SAT_RW":"SAT_MATH",BattleMode.PRIVATE);ids.add(battle);processor.interrupt(battle);}
        var history=access.history(new BattleHistoryQueryDto(id(a),0,100,"createdAt,asc",null,null));assertThat(history.getData()).hasSize(10);assertThat(history.getHistoryLimit()).isEqualTo(10);
        assertThat(access.history(new BattleHistoryQueryDto(id(a),0,100,"createdAt,desc","SAT_RW",null)).getData()).isEmpty();
        for(String suffix:List.of("","/result","/review")) mvc.perform(get("/api/v1/battles/"+ids.getFirst()+suffix).header("Authorization",bearer(a))).andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("HISTORY_ACCESS_REQUIRED"));
        mvc.perform(post("/api/v1/battles/"+ids.getFirst()+"/surrender").header("Authorization",bearer(a))).andExpect(status().isForbidden());
        var third=register();mvc.perform(get("/api/v1/battles/"+ids.getFirst()+"/result").header("Authorization",bearer(third))).andExpect(status().isNotFound());
        grant(a);assertThat(access.history(new BattleHistoryQueryDto(id(a),0,100,"createdAt,desc",null,null)).getData()).hasSize(12);assertThat(processor.result(ids.getFirst(),id(a))).isNotNull();
    }
    @Test void concurrentLastTicketAndConcurrentRefundAreExactlyOnce() throws Exception {
        var a=register();for(int i=0;i<4;i++){var other=register();UUID battle=create(a,other,"SAT_MATH",BattleMode.RANKED);start(battle,a,other);processor.surrender(battle,id(a));}
        var b=register();var c=register();UUID first=create(a,b,"SAT_MATH",BattleMode.RANKED);
        var fixture=waiting(5,BattleMode.RANKED,1000,1000);fixture.getState().getPlayers().get(0).setId(id(a));fixture.getState().getPlayers().get(1).setId(id(c));
        UUID second=battles.create(fixture).getId();
        try(var executor=Executors.newFixedThreadPool(2)){
            var gate=new CountDownLatch(1);var x=executor.submit(() -> {gate.await();return usage.start(first,Map.of(id(a),false,id(b),false),clock.instant());});
            var y=executor.submit(() -> {gate.await();return usage.start(second,Map.of(id(a),false,id(c),false),clock.instant());});gate.countDown();boolean won=x.get(),lost=y.get();assertThat(won).isNotEqualTo(lost);
            UUID charged=won?first:second;assertThat(limits.limits(id(a)).getRankedStartedToday()).isEqualTo(5);
            var refundGate=new CountDownLatch(1);var r1=executor.submit(() -> {refundGate.await();return usage.refund(charged);});var r2=executor.submit(() -> {refundGate.await();return usage.refund(charged);});refundGate.countDown();assertThat(r1.get()).isNotEqualTo(r2.get());
        }
        assertThat(limits.limits(id(a)).getRankedStartedToday()).isEqualTo(4);
    }
    @Test void midnightBetweenQueueAndStartUsesNewDayAfterProDowngrade() throws Exception {
        clock.set(Instant.parse("2026-11-15T04:59:44Z"));var a=register();grant(a);
        for(int i=0;i<5;i++){var other=register();UUID battle=create(a,other,"SAT_MATH",BattleMode.RANKED);start(battle,a,other);processor.surrender(battle,id(a));}
        assertThat(clock.instant()).isEqualTo(Instant.parse("2026-11-15T04:59:59Z"));LocalDate oldDay=EtCalendar.date(clock.instant());
        var b=register();int rating=jdbc.queryForObject("SELECT rating FROM ratings WHERE user_id=? AND discipline_code='SAT_MATH'",Integer.class,id(a));jdbc.update("UPDATE ratings SET rating=? WHERE user_id=? AND discipline_code='SAT_MATH'",rating,id(b));
        matchmaking.search(id(a),"SAT_MATH");UUID battle=matchmaking.search(id(b),"SAT_MATH").getBattleId();presence.connect(id(a),clock.instant());presence.connect(id(b),clock.instant());processor.ready(battle,id(a));processor.ready(battle,id(b));
        setPro(a,false);
        clock.set(clock.instant().plusSeconds(3));processor.tick(battle);assertThat(battles.lock(battle).getPhase()).isEqualTo(BattlePhase.QUESTION);
        assertThat(usage.used(id(a),oldDay)).isEqualTo(5);assertThat(limits.limits(id(a)).getRankedStartedToday()).isEqualTo(1);
    }
    @Test void publicDuelBadgeUsesCurrentRightsWithoutChangingRoomVersion() throws Exception {
        var a=register();grant(a);var room=matchmaking.createDuel(id(a),"SAT_MATH");assertThat(room.getHost().isPro()).isTrue();
        setPro(a,false);
        var refreshed=matchmaking.duel(id(a),room.getId());assertThat(refreshed.getHost().isPro()).isFalse();assertThat(refreshed.getVersion()).isEqualTo(room.getVersion());
    }
    @ParameterizedTest @CsvSource({"NORMAL,RANKED,false,true,true","NORMAL,PRIVATE,true,true,true","OVERTIME_WIN,PRIVATE,false,true,true","SURRENDER,PRIVATE,false,true,false","DISCONNECT,RANKED,false,true,false","SERVER_INTERRUPTION,RANKED,false,false,false","BOTH_DISCONNECTED,PRIVATE,false,false,false"})
    void qualifyingRulesAreSharedAcrossDisciplinesAndRepeatedCallbacksDoNotAddDays(String reason,BattleMode mode,boolean draw,boolean first,boolean second) {
        var a=register();var b=register();var fixture=waiting(5,mode,1000,1000);fixture.getState().getPlayers().get(0).setId(id(a));fixture.getState().getPlayers().get(1).setId(id(b));
        boolean cancelled=reason.equals("SERVER_INTERRUPTION")||reason.equals("BOTH_DISCONNECTED");fixture.setPhase(cancelled?BattlePhase.CANCELLED:BattlePhase.FINISHED);
        var result=new BattleResultDataDto();result.setReason(CompletionReason.valueOf(reason));result.setFinishedAt(clock.instant());result.setWinnerUserId(draw?null:id(a));fixture.setResult(result);
        limits.finish(fixture);limits.finish(fixture);
        assertThat(streaks.current(id(a)).getDailyCurrent()).isEqualTo(first?1:0);assertThat(streaks.current(id(b)).getDailyCurrent()).isEqualTo(second?1:0);
    }
    UUID create(AuthDto a,AuthDto b,String code,BattleMode mode){presence.connect(id(a),clock.instant());presence.connect(id(b),clock.instant());return processor.create(new CreateBattleDto(id(a),id(b),code,mode));}
    void start(UUID battle,AuthDto a,AuthDto b){processor.ready(battle,id(a));processor.ready(battle,id(b));clock.set(clock.instant().plusSeconds(3));processor.tick(battle);}
    UUID id(AuthDto a){return a.getUser().getId();}String bearer(AuthDto a){return "Bearer "+a.getTokens().getAccessToken();}
    AuthDto registerPro(){var d=new RegisterDto(); d.setBirthYear(2000); d.setBirthMonth(1);String s=UUID.randomUUID().toString().replace("-","").substring(0,12);d.setEmail(s+"@example.com");d.setNickname("Billing_"+s);d.setPassword("ExamplePass123!");return auth.register(d);}
    AuthDto register(){var a=registerPro();setPro(a,false);return a;}
    // Existing Free accounts remain supported; these fixtures change rights directly in the test DB.
    void setPro(AuthDto a,boolean pro){jdbc.update("UPDATE subscription_accounts SET pro_active=? WHERE user_id=?",pro,id(a));}
    void grant(AuthDto a){setPro(a,true);}
}
