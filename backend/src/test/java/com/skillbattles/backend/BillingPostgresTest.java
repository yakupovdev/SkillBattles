package com.skillbattles.backend;

import com.fasterxml.jackson.databind.*;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.processor.*;
import com.skillbattles.backend.service.*;
import com.skillbattles.backend.client.StripeBillingClient;
import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.*;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.context.annotation.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.*;
import org.springframework.test.context.bean.override.mockito.*;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.*;
import java.time.*;
import java.nio.file.*;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.concurrent.*;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import static com.skillbattles.backend.BattleFixtures.*;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties={"app.jwt.secret=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=","app.battle.scheduling.enabled=false","app.matchmaking.scheduling.enabled=false","app.billing.webhook-secret=whsec_signed_test_fixture_only","app.billing.monthly-price=price_monthly_fixture","app.billing.annual-price=price_annual_fixture"})
@AutoConfigureMockMvc @Import(BillingPostgresTest.Config.class) @Testcontainers(disabledWithoutDocker=true)
class BillingPostgresTest {
    static final String SECRET="whsec_signed_test_fixture_only";
    @Container static final PostgreSQLContainer<?> POSTGRES=new PostgreSQLContainer<>("postgres:17.12-alpine");
    @DynamicPropertySource static void database(DynamicPropertyRegistry r){r.add("spring.datasource.url",POSTGRES::getJdbcUrl);r.add("spring.datasource.username",POSTGRES::getUsername);r.add("spring.datasource.password",POSTGRES::getPassword);}
    @TestConfiguration static class Config {
        @Bean @Primary MutableClock testClock(){return new MutableClock();}
        @Bean @Primary TestPresence testPresence(){return new TestPresence();}
        @Bean Notifications notifications(){return new Notifications();}
    }
    static class Notifications {final List<AccountChangedEvent> values=new CopyOnWriteArrayList<>();@org.springframework.context.event.EventListener public void event(AccountChangedEvent e){values.add(e);}}
    @Autowired MutableClock clock;@Autowired TestPresence presence;@Autowired AuthProcessor auth;
    @Autowired BillingProcessor billing;@Autowired SubscriptionService subscriptions;@Autowired UsageProcessor limits;@Autowired UsageService usage;
    @Autowired StreakService streaks;@Autowired BattleAccessProcessor access;@Autowired BattleProcessor processor;@Autowired BattleService battles;
    @Autowired MatchmakingProcessor matchmaking;@Autowired QuestionImportProcessor imports;@Autowired QuestionImportFileService files;
    @Autowired JdbcTemplate jdbc;@Autowired MockMvc mvc;@Autowired ObjectMapper json;@Autowired PlatformTransactionManager tx;
    @Autowired Notifications notifications;
    @MockitoBean StripeBillingClient stripe;
    @BeforeEach void setup() throws Exception {
        clock.set(START);presence.clear();notifications.values.clear();jdbc.execute("TRUNCATE question_reports,ranked_usage,battles,questions");uniformTiming(jdbc,10);
        imports.importQuestions(files.read(Path.of(Objects.requireNonNull(getClass().getResource("/fixtures/stage2-questions-test-only.json")).toURI())),false);
        when(stripe.available()).thenReturn(true);
        when(stripe.customer(any())).thenAnswer(call -> "cus_test_"+call.getArgument(0));
        when(stripe.checkout(any(),anyString(),anyString(),any())).thenAnswer(call -> new CheckoutDto("cs_test_"+call.getArgument(3),"https://checkout.stripe.com/c/pay/test_fixture",clock.instant().plusSeconds(1800)));
    }
    @Test void signedPaidWebhookDuplicateAndOutOfOrderAlwaysReconcileCurrentProviderState() throws Exception {
        var a=register();checkout(a);var state=paid(a);when(stripe.latest(customer(a))).thenReturn(state);
        byte[] raw=event(a,"invoice.paid","evt_test_paid");postWebhook(raw,sign(raw),204);postWebhook(raw,sign(raw),204);
        assertThat(subscriptions.entitlements(id(a)).isPro()).isTrue();int version=subscriptions.entitlements(id(a)).getVersion();
        verify(stripe,times(1)).latest(customer(a));assertThat(jdbc.queryForObject("SELECT count(*) FROM stripe_event_receipts WHERE event_id='evt_test_paid'",Integer.class)).isEqualTo(1);
        state.setStatus("CANCELED");when(stripe.latest(customer(a))).thenReturn(state);
        raw=event(a,"customer.subscription.deleted","evt_test_deleted");postWebhook(raw,sign(raw),204);
        raw=event(a,"invoice.paid","evt_test_old_paid");postWebhook(raw,sign(raw),204);
        assertThat(subscriptions.entitlements(id(a)).isPro()).isFalse();assertThat(subscriptions.entitlements(id(a)).getVersion()).isGreaterThan(version);
        assertThat(subscriptions.current(id(a)).getStatus()).isEqualTo("CANCELED");
        mvc.perform(get("/api/v1/users/me").header("Authorization",bearer(a))).andExpect(status().isOk()).andExpect(jsonPath("$.isPro").value(false));
    }
    @Test void unpaidCheckoutFailedRenewalAndPaidPeriodExpiryNeverGrantOrExtendPro() throws Exception {
        var a=register();checkout(a);var state=paid(a);state.setInvoicePaid(false);when(stripe.latest(customer(a))).thenReturn(state);
        hook(a,"checkout.session.completed");assertThat(subscriptions.entitlements(id(a)).isPro()).isFalse();
        state.setInvoicePaid(true);state.setCancelAtPeriodEnd(true);when(stripe.latest(customer(a))).thenReturn(state);hook(a,"invoice.paid");
        assertThat(subscriptions.entitlements(id(a)).isPro()).isTrue();int version=subscriptions.entitlements(id(a)).getVersion();
        clock.set(state.getCurrentPeriodEnd());assertThat(subscriptions.entitlements(id(a)).isPro()).isFalse();assertThat(subscriptions.entitlements(id(a)).getVersion()).isGreaterThan(version);
        subscriptions.expire();assertThat(subscriptions.current(id(a)).getStatus()).isEqualTo("EXPIRED");
        clock.set(START);state.setStatus("PAST_DUE");when(stripe.latest(customer(a))).thenReturn(state);hook(a,"invoice.payment_failed");
        assertThat(subscriptions.entitlements(id(a)).isPro()).isFalse();
    }
    @Test void signatureRawBodyTimeWindowAndLiveEventsAreRejected() throws Exception {
        var a=register();checkout(a);byte[] raw=event(a,"invoice.paid","evt_test_invalid");
        postWebhook(raw,"t=0,v1=bad",400);postWebhook(raw,null,400);
        postWebhook((new String(raw,StandardCharsets.UTF_8)+" ").getBytes(StandardCharsets.UTF_8),sign(raw),400);
        var live=json.readTree(raw);((com.fasterxml.jackson.databind.node.ObjectNode)live).put("livemode",true);byte[] liveRaw=json.writeValueAsBytes(live);postWebhook(liveRaw,sign(liveRaw),400);
        String old=sign(raw);clock.set(START.plusSeconds(301));postWebhook(raw,old,400);
        verify(stripe,never()).latest(anyString());assertThat(subscriptions.entitlements(id(a)).isPro()).isFalse();
    }
    @Test void concurrentCheckoutReusesRequestAndRejectsConflictingRequestsWithoutSecondSubscription() throws Exception {
        var a=register();UUID request=UUID.randomUUID();
        try(var executor=Executors.newFixedThreadPool(2)) {
            var start=new CountDownLatch(1);var x=executor.submit(() -> {start.await();return billing.checkout(id(a),"PRO_MONTHLY",request);});
            var y=executor.submit(() -> {start.await();return billing.checkout(id(a),"PRO_MONTHLY",request);});start.countDown();assertThat(x.get()).isEqualTo(y.get());
        }
        verify(stripe,times(1)).customer(id(a));verify(stripe,times(1)).checkout(eq(id(a)),anyString(),eq("PRO_MONTHLY"),eq(request));
        assertThatThrownBy(() -> billing.checkout(id(a),"PRO_ANNUAL",request)).hasMessageContaining("another checkout");
        assertThatThrownBy(() -> billing.checkout(id(a),"PRO_MONTHLY",UUID.randomUUID())).hasMessageContaining("already in progress");
        var state=paid(a);when(stripe.latest(customer(a))).thenReturn(state);hook(a,"invoice.paid");
        assertThatThrownBy(() -> billing.checkout(id(a),"PRO_MONTHLY",UUID.randomUUID())).hasMessageContaining("already active");
        assertThat(billing.checkout(id(a),"PRO_MONTHLY",request).getCheckoutSessionId()).startsWith("cs_test_");
    }
    @Test void absentStripeKeepsFreeAndFailsPaymentsClosedWithoutPublicPlanSwitch() throws Exception {
        var a=register();when(stripe.available()).thenReturn(false);
        mvc.perform(get("/api/v1/subscriptions/plans")).andExpect(status().isOk()).andExpect(jsonPath("$[1].amountCents").value(799)).andExpect(jsonPath("$[2].amountCents").value(4799)).andExpect(jsonPath("$[1].checkoutAvailable").value(false));
        mvc.perform(post("/api/v1/subscriptions/checkout").header("Authorization",bearer(a)).contentType("application/json").content("{\"planCode\":\"PRO_MONTHLY\",\"requestId\":\""+UUID.randomUUID()+"\"}")).andExpect(status().isServiceUnavailable()).andExpect(jsonPath("$.code").value("BILLING_UNAVAILABLE"));
        mvc.perform(post("/api/v1/subscriptions/portal").header("Authorization",bearer(a))).andExpect(status().isServiceUnavailable());
        mvc.perform(get("/api/v1/users/me/limits").header("Authorization",bearer(a))).andExpect(status().isOk()).andExpect(jsonPath("$.freeRankedRemaining").value(5)).andExpect(header().string("Cache-Control","no-store"));
        mvc.perform(post("/api/v1/subscriptions/checkout").header("Authorization",bearer(a)).contentType("application/json").content("{\"planCode\":\"PRO_MONTHLY\",\"requestId\":\""+UUID.randomUUID()+"\",\"userId\":\""+UUID.randomUUID()+"\"}")).andExpect(status().isBadRequest());
        mvc.perform(get("/api/v1/subscriptions/me")).andExpect(status().isUnauthorized());
        assertThat(subscriptions.entitlements(id(a)).isPro()).isFalse();
    }
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
        var state=paid(a);state.setStatus("CANCELED");when(stripe.latest(customer(a))).thenReturn(state);hook(a,"customer.subscription.deleted");
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
        var state=paid(a);state.setStatus("CANCELED");when(stripe.latest(customer(a))).thenReturn(state);hook(a,"customer.subscription.deleted");
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
    @Test void webhookReceiptRightsAndNotificationsRollBackTogether() throws Exception {
        var a=register();checkout(a);when(stripe.latest(customer(a))).thenReturn(paid(a));byte[] raw=event(a,"invoice.paid","evt_test_rollback");String signature=sign(raw);
        assertThatThrownBy(() -> new TransactionTemplate(tx).execute(status -> {billing.webhook(raw,signature);throw new IllegalStateException("Test-only rollback");})).isInstanceOf(IllegalStateException.class);
        assertThat(subscriptions.processed("evt_test_rollback")).isFalse();assertThat(subscriptions.entitlements(id(a)).isPro()).isFalse();assertThat(notifications.values).isEmpty();
        postWebhook(raw,signature,204);assertThat(subscriptions.entitlements(id(a)).isPro()).isTrue();assertThat(notifications.values).hasSize(1);
    }
    @Test void midnightBetweenQueueAndStartUsesNewDayAfterProDowngrade() throws Exception {
        clock.set(Instant.parse("2026-11-15T04:59:44Z"));var a=register();grant(a);
        for(int i=0;i<5;i++){var other=register();UUID battle=create(a,other,"SAT_MATH",BattleMode.RANKED);start(battle,a,other);processor.surrender(battle,id(a));}
        assertThat(clock.instant()).isEqualTo(Instant.parse("2026-11-15T04:59:59Z"));LocalDate oldDay=EtCalendar.date(clock.instant());
        var b=register();int rating=jdbc.queryForObject("SELECT rating FROM ratings WHERE user_id=? AND discipline_code='SAT_MATH'",Integer.class,id(a));jdbc.update("UPDATE ratings SET rating=? WHERE user_id=? AND discipline_code='SAT_MATH'",rating,id(b));
        matchmaking.search(id(a),"SAT_MATH");UUID battle=matchmaking.search(id(b),"SAT_MATH").getBattleId();presence.connect(id(a),clock.instant());presence.connect(id(b),clock.instant());processor.ready(battle,id(a));processor.ready(battle,id(b));
        var state=paid(a);state.setStatus("CANCELED");when(stripe.latest(customer(a))).thenReturn(state);hook(a,"customer.subscription.deleted");
        clock.set(clock.instant().plusSeconds(3));processor.tick(battle);assertThat(battles.lock(battle).getPhase()).isEqualTo(BattlePhase.QUESTION);
        assertThat(usage.used(id(a),oldDay)).isEqualTo(5);assertThat(limits.limits(id(a)).getRankedStartedToday()).isEqualTo(1);
    }
    @Test void twoDifferentConcurrentCheckoutsCreateOnlyOneSession() throws Exception {
        var a=register();
        try(var executor=Executors.newFixedThreadPool(2)) {
            var gate=new CountDownLatch(1);Callable<String> create=() -> {gate.await();try{billing.checkout(id(a),"PRO_MONTHLY",UUID.randomUUID());return "CREATED";}catch(com.skillbattles.backend.exception.BusinessException e){return e.getCode();}};
            var first=executor.submit(create);var second=executor.submit(create);gate.countDown();assertThat(List.of(first.get(),second.get())).containsExactlyInAnyOrder("CREATED","CHECKOUT_IN_PROGRESS");
        }
        verify(stripe,times(1)).checkout(eq(id(a)),anyString(),eq("PRO_MONTHLY"),any());assertThat(subscriptions.account(id(a)).getCheckouts()).hasSize(1);
    }
    @Test void subscriptionDowngradeAndRankedStartAreSerializedOnAccountState() throws Exception {
        var a=register();grant(a);
        for(int i=0;i<5;i++){var other=register();UUID old=create(a,other,"SAT_MATH",BattleMode.RANKED);start(old,a,other);processor.surrender(old,id(a));}
        var b=register();UUID battle=create(a,b,"SAT_MATH",BattleMode.RANKED);processor.ready(battle,id(a));processor.ready(battle,id(b));clock.set(clock.instant().plusSeconds(3));
        var cancelled=paid(a);cancelled.setStatus("CANCELED");when(stripe.latest(customer(a))).thenReturn(cancelled);byte[] raw=event(a,"customer.subscription.deleted","evt_test_start_race");String signature=sign(raw);
        List<Future<?>> pending=new ArrayList<>();
        try(var executor=Executors.newFixedThreadPool(2)) {
            new TransactionTemplate(tx).executeWithoutResult(status -> {
                processor.tick(battle);pending.add(executor.submit(() -> billing.webhook(raw,signature)));
                var blocked=executor.submit(() -> {for(int attempt=0;attempt<500;attempt++){if(jdbc.queryForObject("SELECT count(*) FROM pg_stat_activity WHERE datname=current_database() AND wait_event_type='Lock'",Integer.class)>0)return true;Thread.sleep(10);}return false;});
                try{assertThat(blocked.get(10,TimeUnit.SECONDS)).isTrue();}catch(Exception e){throw new AssertionError(e);}assertThat(pending.getFirst().isDone()).isFalse();
                assertThat(limits.limits(id(a)).getRankedStartedToday()).isEqualTo(6);
            });pending.getFirst().get(10,TimeUnit.SECONDS);
        }
        assertThat(subscriptions.entitlements(id(a)).isPro()).isFalse();assertThat(limits.limits(id(a)).getFreeRankedRemaining()).isZero();assertThat(battles.lock(battle).getPhase()).isEqualTo(BattlePhase.QUESTION);
    }
    @Test void publicDuelBadgeUsesCurrentRightsWithoutChangingRoomVersion() throws Exception {
        var a=register();grant(a);var room=matchmaking.createDuel(id(a),"SAT_MATH");assertThat(room.getHost().isPro()).isTrue();
        var state=paid(a);state.setStatus("CANCELED");when(stripe.latest(customer(a))).thenReturn(state);hook(a,"customer.subscription.deleted");
        var refreshed=matchmaking.duel(id(a),room.getId());assertThat(refreshed.getHost().isPro()).isFalse();assertThat(refreshed.getVersion()).isEqualTo(room.getVersion());
    }
    @Test void lateCancellationCannotReleaseANewerOpenCheckoutReservation() throws Exception {
        var a=register();grant(a);var state=paid(a);state.setStatus("CANCELED");when(stripe.latest(customer(a))).thenReturn(state);hook(a,"customer.subscription.deleted");
        UUID second=UUID.randomUUID();billing.checkout(id(a),"PRO_MONTHLY",second);Instant until=subscriptions.account(id(a)).getCheckouts().get(second).getReservedUntil();
        hook(a,"customer.subscription.deleted");
        assertThat(subscriptions.account(id(a)).getCheckouts().get(second).getReservedUntil()).isEqualTo(until);
        assertThatThrownBy(() -> billing.checkout(id(a),"PRO_MONTHLY",UUID.randomUUID())).hasMessageContaining("already in progress");
        verify(stripe,times(2)).checkout(eq(id(a)),anyString(),eq("PRO_MONTHLY"),any());
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
    AuthDto register(){var d=new RegisterDto(); d.setBirthYear(2000); d.setBirthMonth(1);String s=UUID.randomUUID().toString().replace("-","").substring(0,12);d.setEmail(s+"@example.com");d.setNickname("Billing_"+s);d.setPassword("ExamplePass123!");return auth.register(d);}
    void checkout(AuthDto a){billing.checkout(id(a),"PRO_MONTHLY",UUID.randomUUID());}
    String customer(AuthDto a){return subscriptions.account(id(a)).getCustomerId();}
    ProviderSubscriptionDto paid(AuthDto a){return new ProviderSubscriptionDto(customer(a),"sub_test_"+id(a),"price_monthly_fixture","ACTIVE",clock.instant().minusSeconds(1),clock.instant().plusSeconds(3600),false,true,false);}
    void grant(AuthDto a) throws Exception {checkout(a);when(stripe.latest(customer(a))).thenReturn(paid(a));hook(a,"invoice.paid");}
    void hook(AuthDto a,String type) throws Exception {byte[] raw=event(a,type,"evt_test_"+UUID.randomUUID());postWebhook(raw,sign(raw),204);}
    byte[] event(AuthDto a,String type,String event) throws Exception {return json.writeValueAsBytes(Map.of("id",event,"object","event","type",type,"livemode",false,"created",clock.instant().getEpochSecond(),"data",Map.of("object",Map.of("id","fixture_object","object","subscription","customer",customer(a),"livemode",false))));}
    String sign(byte[] raw) throws Exception {long now=clock.instant().getEpochSecond();var mac=Mac.getInstance("HmacSHA256");mac.init(new SecretKeySpec(SECRET.getBytes(StandardCharsets.UTF_8),"HmacSHA256"));byte[] payload=(now+"."+new String(raw,StandardCharsets.UTF_8)).getBytes(StandardCharsets.UTF_8);return "t="+now+",v1="+HexFormat.of().formatHex(mac.doFinal(payload));}
    void postWebhook(byte[] raw,String signature,int expected) throws Exception {var r=post("/api/v1/subscriptions/webhook").contentType("application/json").content(raw);if(signature!=null)r.header("Stripe-Signature",signature);mvc.perform(r).andExpect(status().is(expected));}
}
