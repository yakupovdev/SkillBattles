package com.skillbattles.backend;

import com.fasterxml.jackson.databind.*;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.exception.*;
import com.skillbattles.backend.processor.*;
import com.skillbattles.backend.service.*;
import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.*;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.context.annotation.*;
import org.springframework.context.event.EventListener;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.*;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.*;
import java.net.URI;
import java.net.http.HttpClient;
import java.nio.file.Path;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import static com.skillbattles.backend.BattleFixtures.*;
import static org.assertj.core.api.Assertions.*;
import static org.awaitility.Awaitility.await;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {
        "app.jwt.secret=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=", "app.battle.scheduling.enabled=false",
        "app.matchmaking.scheduling.enabled=false", "app.realtime.monitor-ms=3600000"})
@AutoConfigureMockMvc
@Import(RematchInvitationsPostgresTest.Config.class)
@Testcontainers(disabledWithoutDocker = true)
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
class RematchInvitationsPostgresTest {
    static final String PATH = "/api/v1/users/me/rematch-invitations";
    @Container static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:17.12-alpine");
    @DynamicPropertySource static void database(DynamicPropertyRegistry r) {
        r.add("spring.datasource.url", POSTGRES::getJdbcUrl); r.add("spring.datasource.username", POSTGRES::getUsername); r.add("spring.datasource.password", POSTGRES::getPassword);
    }
    @TestConfiguration static class Config {
        @Bean @Primary MutableClock testClock() { return new MutableClock(); }
        @Bean @Primary TestPresence testPresence() { return new TestPresence(); }
        @Bean Changes changes() { return new Changes(); }
    }
    static class Changes {
        final List<RematchChangedEvent> values = new CopyOnWriteArrayList<>();
        @EventListener public void changed(RematchChangedEvent event) { values.add(event); }
    }
    @Autowired AuthProcessor auth;
    @Autowired RematchProcessor rematches;
    @Autowired MatchmakingProcessor matchmaking;
    @Autowired MatchmakingRegistryService registry;
    @MockitoSpyBean BattleProcessor processor;
    @MockitoSpyBean BattleService battles;
    @MockitoSpyBean UserService users;
    @MockitoSpyBean SubscriptionService subscriptions;
    @Autowired QuestionService questions;
    @Autowired QuestionImportFileService files;
    @Autowired RealtimeSessionService sessions;
    @Autowired MutableClock clock;
    @Autowired TestPresence presence;
    @Autowired Changes changes;
    @Autowired PlatformTransactionManager transactions;
    @Autowired JdbcTemplate jdbc;
    @Autowired ObjectMapper json;
    @Autowired MockMvc mvc;
    @LocalServerPort int port;
    final List<NativeStompClient> clients = new ArrayList<>();
    final HttpClient http = HttpClient.newHttpClient();

    @BeforeEach void setup() throws Exception {
        clock.set(START); presence.clear();
        registry.transact(s -> {s.getRematches().clear();s.getEntries().clear();s.getDuels().clear();s.getActivities().clear();return null;});
        jdbc.execute("TRUNCATE question_reports,ranked_usage,battles,questions");
        uniformTiming(jdbc,10);
        questions.importQuestions(files.read(Path.of(getClass().getResource("/fixtures/stage2-questions-test-only.json").toURI())),false);
        changes.values.clear();
    }
    @AfterEach void cleanup() {
        clients.forEach(NativeStompClient::close);
        await().atMost(Duration.ofSeconds(5)).until(() -> !sessions.hasSubscribers());
        http.close();
    }

    @Test void jwtPersonalSnapshotIsMinimalNoStoreAndDoesNotGrantHistoryAccess() throws Exception {
        var a=register();var b=register();var c=register();UUID source=source(a,b);
        var pending=rematches.request(source,id(a));
        assertThat(incoming(a).path("data")).isEmpty();
        assertThat(incoming(c).path("data")).isEmpty();
        var result=incoming(b);
        assertThat(result.path("serverTime").asText()).isEqualTo(clock.instant().toString());
        var entry=result.path("data").get(0);
        assertThat(fieldNames(entry)).containsExactlyInAnyOrder("sourceBattleId","requester","disciplineCode","expiresAt","version");
        assertThat(fieldNames(entry.path("requester"))).containsExactlyInAnyOrder("id","nickname","isPro");
        assertThat(entry.path("sourceBattleId").asText()).isEqualTo(source.toString());
        assertThat(entry.path("requester").path("id").asText()).isEqualTo(id(a).toString());
        assertThat(entry.path("requester").path("nickname").asText()).isEqualTo(a.getUser().getNickname());
        assertThat(entry.path("disciplineCode").asText()).isEqualTo("SAT_MATH");
        assertThat(entry.path("expiresAt").asText()).isEqualTo(pending.getExpiresAt().toString());
        assertThat(entry.toString()).doesNotContain("email","birth","password","token","question","explanation","participants");
        mvc.perform(get(PATH)).andExpect(status().isUnauthorized());
        mvc.perform(get(PATH).header("Authorization","Bearer "+a.getTokens().getRefreshToken())).andExpect(status().isUnauthorized());
        mvc.perform(get(PATH).header("Authorization","Bearer invalid")).andExpect(status().isUnauthorized());
        assertThat(incoming(b,"?userId="+id(c))).isEqualTo(result);
    }

    @Test void multipleIncomingAreSortedAndMetadataIsBatchedOutsideRegistryLock() throws Exception {
        var b=register();var a=register();var c=register();var d=register();
        UUID ab=source(a,b),cb=source(c,b),db=source(d,b);
        var first=rematches.request(ab,id(a));clock.set(clock.instant().plusSeconds(1));
        var second=rematches.request(cb,id(c));var third=rematches.request(db,id(d));
        var profile=new ProfileUpdateDto();profile.setNickname("Updated_"+suffix());users.update(id(a),profile);
        grant(a);
        clearInvocations(users,subscriptions,battles);
        var result=rematches.invitations(id(b));
        var expected=List.of(first,second,third).stream().sorted(Comparator.comparing(RematchDto::getExpiresAt).thenComparing(r->r.getSourceBattleId().toString())).map(RematchDto::getSourceBattleId).toList();
        assertThat(result.getData()).extracting(RematchInvitationDto::getSourceBattleId).containsExactlyElementsOf(expected);
        assertThat(result.getData().getFirst().getRequester().getNickname()).isEqualTo(profile.getNickname());
        assertThat(result.getData().getFirst().getRequester().isPro()).isTrue();
        verify(users,times(1)).findByIds(Set.of(id(a),id(c),id(d)));
        verify(subscriptions,times(1)).proFlags(Set.of(id(a),id(c),id(d)));
        verify(battles,never()).getForParticipant(any(),any());
        clearInvocations(users,subscriptions);
        assertThat(rematches.invitations(id(a)).getData()).isEmpty();
        verify(users,never()).findByIds(any());verify(subscriptions,never()).proFlags(any());
    }

    @Test void exactDeadlineReadRetriesAndExpiryEventsNeverRenewTheWindow() throws Exception {
        var a=register();var b=register();UUID source=source(a,b);
        var original=rematches.request(source,id(a));
        clock.set(original.getExpiresAt().minusNanos(1));
        assertThat(incoming(b).path("data")).hasSize(1);
        assertThat(rematches.request(source,id(a))).isEqualTo(original);
        clock.set(original.getExpiresAt());
        assertThat(incoming(b).path("data")).isEmpty();
        assertThat(rematches.get(source,id(b)).getStatus()).isEqualTo("EXPIRED");
        assertThat(rematches.get(source,id(b)).getVersion()).isEqualTo(2);
        assertThat(rematches.invitations(id(b)).getData()).isEmpty();
        assertThat(changes.values.stream().filter(e->e.rematch().getStatus().equals("EXPIRED"))).hasSize(1);
        mvc.perform(post(rematch(source)).header("Authorization",bearer(b))).andExpect(status().isGone()).andExpect(jsonPath("$.code").value("REMATCH_EXPIRED"));
        mvc.perform(delete(rematch(source)).header("Authorization",bearer(b))).andExpect(status().isNoContent());
        assertThat(matchmaking.activity(id(a)).getType()).isEqualTo(ActivityType.NONE);
    }

    @Test void acceptanceDoesNotCancelOtherIncomingInvitationsOrSkipReadiness() throws Exception {
        var a=register();var b=register();var c=register();UUID ab=source(a,b),cb=source(c,b);
        rematches.request(ab,id(a));rematches.request(cb,id(c));
        var matched=rematches.request(ab,id(b));
        assertThat(rematches.request(ab,id(b)).getBattleId()).isEqualTo(matched.getBattleId());
        assertThat(battles.getForParticipant(matched.getBattleId(),id(b)).getPhase()).isEqualTo(BattlePhase.WAITING_READY);
        assertThat(battles.getForParticipant(matched.getBattleId(),id(a)).getState().getPlayers()).allMatch(p->!p.isReady());
        assertThat(incoming(b).path("data")).hasSize(1);
        assertThat(incoming(b).path("data").get(0).path("sourceBattleId").asText()).isEqualTo(cb.toString());
        assertThatThrownBy(()->rematches.request(cb,id(b))).isInstanceOfSatisfying(ConflictException.class,e->assertThat(e.getCode()).isEqualTo("ACTIVITY_CONFLICT"));
        assertThat(rematches.get(cb,id(c)).getStatus()).isEqualTo("WAITING");
        mvc.perform(delete(rematch(ab)).header("Authorization",bearer(b))).andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("MATCH_ALREADY_FOUND"));
        rematches.cancel(cb,id(b));rematches.cancel(cb,id(b));
        assertThat(incoming(b).path("data")).isEmpty();
        assertThat(matchmaking.activity(id(c)).getType()).isEqualTo(ActivityType.NONE);
        assertThat(matchmaking.activity(id(b)).getBattleId()).isEqualTo(matched.getBattleId());
    }

    @ParameterizedTest @ValueSource(strings={"QUEUE","DUEL","BATTLE"})
    void recipientActivityIsNeverReservedLeftOrCancelledByAnInvitation(String kind) throws Exception {
        var a=register();var b=register();var c=register();UUID source=source(a,b);
        if(kind.equals("QUEUE"))matchmaking.search(id(b),"SAT_MATH");
        else if(kind.equals("DUEL"))matchmaking.createDuel(id(b),"SAT_MATH");
        else processor.create(new CreateBattleDto(id(b),id(c),"SAT_MATH",BattleMode.PRIVATE));
        var before=matchmaking.activity(id(b));
        rematches.request(source,id(a));
        assertThat(incoming(b).path("data")).hasSize(1);
        assertThat(matchmaking.activity(id(b))).isEqualTo(before);
        assertThatThrownBy(()->rematches.request(source,id(b))).isInstanceOf(ConflictException.class);
        rematches.cancel(source,id(b));
        assertThat(matchmaking.activity(id(b))).isEqualTo(before);
        assertThat(matchmaking.activity(id(a)).getType()).isEqualTo(ActivityType.NONE);
    }

    @Test void sourceHistoryPolicyRemainsAuthoritativeWhileMinimalInvitationIsVisible() throws Exception {
        var a=register();var b=register();var c=register();UUID source=source(a,b);
        for(int n=0;n<11;n++)source(b,c);
        rematches.request(source,id(a));
        assertThat(incoming(b).path("data")).hasSize(1);
        mvc.perform(get(rematch(source)).header("Authorization",bearer(b))).andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("HISTORY_ACCESS_REQUIRED"));
        mvc.perform(post(rematch(source)).header("Authorization",bearer(b))).andExpect(status().isForbidden());
        mvc.perform(get("/api/v1/battles/"+source+"/review").header("Authorization",bearer(b))).andExpect(status().isForbidden());
        rematches.cancel(source,id(b));assertThat(incoming(b).path("data")).isEmpty();
    }

    @Test void metadataFailureIsAnErrorAndNeverAnEmptySuccessSnapshot() throws Exception {
        var a=register();var b=register();UUID source=source(a,b);rematches.request(source,id(a));
        doThrow(new IllegalStateException("test-only metadata failure")).when(users).findByIds(any());
        mvc.perform(get(PATH).header("Authorization",bearer(b))).andExpect(status().isInternalServerError()).andExpect(jsonPath("$.code").value("INTERNAL_ERROR"));
    }

    @Test void metadataEnrichmentReleasesRegistryLockAndKeepsTheCapturedSnapshot() throws Exception {
        var a=register();var b=register();UUID source=source(a,b);var waiting=rematches.request(source,id(a));
        var pool=Executors.newSingleThreadExecutor();
        doAnswer(call->{
            pool.submit(()->rematches.cancel(source,id(b))).get(5,TimeUnit.SECONDS);
            return call.callRealMethod();
        }).when(users).findByIds(any());
        try {
            var snapshot=rematches.invitations(id(b));
            assertThat(snapshot.getData()).hasSize(1);
            assertThat(snapshot.getData().getFirst().getVersion()).isEqualTo(waiting.getVersion());
            assertThat(rematches.get(source,id(b)).getStatus()).isEqualTo("CANCELLED");
            assertThat(rematches.invitations(id(b)).getData()).isEmpty();
        } finally { pool.shutdownNow(); }
    }

    @Test void simultaneousFirstConsentsAndRetriesCreateExactlyOneNewBattle() throws Exception {
        var a=register();var b=register();UUID source=source(a,b);
        var results=race(()->rematches.request(source,id(a)).getStatus(),()->rematches.request(source,id(b)).getStatus());
        assertThat(results).containsExactlyInAnyOrder("WAITING","MATCHED");
        var matched=rematches.get(source,id(a));
        assertThat(matched.getVersion()).isEqualTo(2);
        assertThat(rematches.request(source,id(a)).getBattleId()).isEqualTo(matched.getBattleId());
        assertThat(rematches.request(source,id(b)).getBattleId()).isEqualTo(matched.getBattleId());
        assertThat(jdbc.queryForObject("SELECT count(*) FROM battles",Integer.class)).isEqualTo(2);
        assertThat(battles.getForParticipant(matched.getBattleId(),id(b)).getPhase()).isEqualTo(BattlePhase.WAITING_READY);
        assertThat(incoming(a).path("data")).isEmpty();assertThat(incoming(b).path("data")).isEmpty();
    }

    @Test void failedAcceptanceRollsBackCreatedBattleAndKeepsPendingReservation() throws Exception {
        var a=register();var b=register();UUID source=source(a,b);var pending=rematches.request(source,id(a));
        long before=jdbc.queryForObject("SELECT count(*) FROM battles",Long.class);
        doAnswer(call->{call.callRealMethod();throw new IllegalStateException("test-only post-create failure");}).when(processor).create(any());
        assertThatThrownBy(()->rematches.request(source,id(b))).isInstanceOf(IllegalStateException.class);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM battles",Long.class)).isEqualTo(before);
        assertThat(rematches.get(source,id(b))).isEqualTo(pending);
        assertThat(incoming(b).path("data")).hasSize(1);
        assertThat(matchmaking.activity(id(a)).getResourceId()).isEqualTo(source);
        assertThat(changes.values).noneMatch(e->e.rematch().getStatus().equals("MATCHED"));
    }

    @Test void missingContentAndBusyRequesterPreserveWaitingAndOnlyMatchingReservationIsReleased() throws Exception {
        var a=register();var b=register();UUID source=source(a,b);var pending=rematches.request(source,id(a));
        jdbc.update("UPDATE questions SET active=false");
        assertThatThrownBy(()->rematches.request(source,id(b))).isInstanceOfSatisfying(ConflictException.class,e->assertThat(e.getCode()).isEqualTo("CONTENT_UNAVAILABLE"));
        assertThat(rematches.get(source,id(a))).isEqualTo(pending);
        UUID other=UUID.randomUUID();var replacement=new ActivityReservationDto(ActivityType.QUEUE,other,null);
        registry.transact(s->{s.getActivities().put(id(a),replacement);return null;});
        assertThatThrownBy(()->rematches.request(source,id(b))).isInstanceOfSatisfying(ConflictException.class,e->assertThat(e.getCode()).isEqualTo("ACTIVITY_CONFLICT"));
        rematches.cancel(source,id(b));
        var retained=registry.transact(s->s.getActivities().get(id(a)));
        assertThat(retained).isEqualTo(replacement);
        assertThat(incoming(b).path("data")).isEmpty();
    }

    @Test void acceptCancelAndExpiryRacesCreateAtMostOneBattle() throws Exception {
        var a=register();var b=register();UUID source=source(a,b);rematches.request(source,id(a));
        var answers=race(()->{rematches.request(source,id(b));return "MATCHED";},()->{rematches.cancel(source,id(b));return "CANCELLED";});
        var outcome=rematches.get(source,id(a));
        assertThat(outcome.getStatus()).isIn("MATCHED","CANCELLED");
        assertThat(jdbc.queryForObject("SELECT count(*) FROM battles",Integer.class)).isEqualTo(outcome.getStatus().equals("MATCHED")?2:1);
        assertThat(answers).hasSize(2);
        if(outcome.getStatus().equals("MATCHED"))processor.surrender(outcome.getBattleId(),id(a));
        UUID next=source(a,b);var pending=rematches.request(next,id(a));
        race(()->{rematches.request(next,id(b));return "MATCHED";},()->registry.transact(s->{clock.set(pending.getExpiresAt());RematchExpiry.expire(s,clock.instant());return "EXPIRED";}));
        var terminal=rematches.get(next,id(a));assertThat(terminal.getStatus()).isIn("MATCHED","EXPIRED");
        assertThat(terminal.getVersion()).isEqualTo(2);
        assertThat(incoming(b).path("data")).isEmpty();
    }

    @Test void realStompCommitRollbackCurrentSessionAndReconnectRecovery() throws Exception {
        var a=register();var b=register();var c=register();UUID first=source(a,b),second=source(a,b);
        var ca=connect(a);var oldB=connect(b);var third=connect(c);
        new TransactionTemplate(transactions).executeWithoutResult(tx->{
            rematches.request(first,id(a));
            try {assertThat(oldB.hasEvent(RematchInvitationsPostgresTest::rematchEvent,Duration.ofMillis(150))).isFalse();}
            catch(Exception e){throw new RuntimeException(e);}tx.setRollbackOnly();
        });
        assertThat(incoming(b).path("data")).isEmpty();
        assertThat(oldB.hasEvent(RematchInvitationsPostgresTest::rematchEvent,Duration.ofMillis(150))).isFalse();
        var pending=rematches.request(first,id(a));
        for(var client:List.of(ca,oldB)) {
            var event=client.event(RematchInvitationsPostgresTest::rematchEvent);
            assertThat(event.path("resourceId").asText()).isEqualTo(first.toString());
            assertThat(event.path("version").asInt()).isEqualTo(1);
            assertThat(fieldNames(event.path("data"))).containsExactlyInAnyOrder("sourceBattleId","status","requestedBy","expiresAt","battleId","version");
        }
        assertThat(third.hasEvent(RematchInvitationsPostgresTest::rematchEvent,Duration.ofMillis(150))).isFalse();
        rematches.request(first,id(a));
        assertThat(oldB.hasEvent(RematchInvitationsPostgresTest::rematchEvent,Duration.ofMillis(150))).isFalse();
        clock.set(clock.instant().plusSeconds(5));
        var currentB=connect(b);oldB.closed.get(5,TimeUnit.SECONDS);
        assertThat(incoming(b).path("data").get(0).path("expiresAt").asText()).isEqualTo(pending.getExpiresAt().toString());
        rematches.cancel(first,id(b));
        currentB.event(e->rematchEvent(e)&&e.path("data").path("status").asText().equals("CANCELLED"));
        rematches.request(second,id(a));
        var fresh=currentB.event(e->rematchEvent(e)&&e.path("resourceId").asText().equals(second.toString()));
        assertThat(fresh.path("data").path("status").asText()).isEqualTo("WAITING");
        assertThat(oldB.hasEvent(RematchInvitationsPostgresTest::rematchEvent,Duration.ofMillis(150))).isFalse();
        assertThat(third.hasEvent(RematchInvitationsPostgresTest::rematchEvent,Duration.ofMillis(150))).isFalse();
    }

    static boolean rematchEvent(JsonNode event){return event.path("type").asText().equals("REMATCH_CHANGED");}
    static Set<String> fieldNames(JsonNode node){Set<String> names=new TreeSet<>();node.fieldNames().forEachRemaining(names::add);return names;}
    JsonNode incoming(AuthDto user)throws Exception{return incoming(user,"");}
    JsonNode incoming(AuthDto user,String query)throws Exception{return json.readTree(mvc.perform(get(PATH+query).header("Authorization",bearer(user))).andExpect(status().isOk()).andExpect(header().stringValues("Cache-Control","no-store")).andReturn().getResponse().getContentAsByteArray());}
    NativeStompClient connect(AuthDto user)throws Exception {
        var client=new NativeStompClient(http,URI.create("ws://localhost:"+port+"/ws/v1/events"),"http://localhost:"+port,json);clients.add(client);
        client.connect(user.getTokens().getAccessToken());client.await("CONNECTED");client.startHeartbeats();client.subscribe("/user/queue/events");
        await().atMost(Duration.ofSeconds(5)).until(()->sessions.target(id(user)).isPresent());return client;
    }
    UUID source(AuthDto a,AuthDto b) {
        UUID battle=processor.create(new CreateBattleDto(id(a),id(b),"SAT_MATH",BattleMode.PRIVATE));
        presence.connect(id(a),clock.instant());presence.connect(id(b),clock.instant());processor.ready(battle,id(a));processor.ready(battle,id(b));
        clock.set(clock.instant().plusSeconds(3));processor.tick(battle);var state=battles.getForParticipant(battle,id(a));
        processor.answer(battle,id(a),BattleFixtures.answer(state,false),clock.instant());processor.surrender(battle,id(b));clock.set(clock.instant().plusSeconds(1));return battle;
    }
    AuthDto register(){var dto=new RegisterDto();dto.setBirthYear(2000);dto.setBirthMonth(1);dto.setEmail(suffix()+"@example.com");dto.setNickname("Invite_"+suffix());dto.setPassword("ExamplePass123!");return auth.register(dto);}
    String suffix(){return UUID.randomUUID().toString().replace("-","").substring(0,10);}
    UUID id(AuthDto user){return user.getUser().getId();}
    String bearer(AuthDto user){return "Bearer "+user.getTokens().getAccessToken();}
    String rematch(UUID source){return "/api/v1/battles/"+source+"/rematch";}
    void grant(AuthDto user){String customer="cus_fixture_"+id(user);subscriptions.bindCustomer(id(user),customer);subscriptions.apply(id(user),"evt_fixture_"+UUID.randomUUID(),new ProviderSubscriptionDto(customer,"sub_fixture_"+id(user),"price_fixture","ACTIVE",START.minusSeconds(1),START.plusSeconds(86400),false,true,false),"PRO_MONTHLY");}
    List<String> race(Callable<String> a,Callable<String> b)throws Exception {
        var gate=new CountDownLatch(1);
        try(var pool=Executors.newFixedThreadPool(2)){
            List<Future<String>> futures=new ArrayList<>();for(var action:List.of(a,b))futures.add(pool.submit(()->{gate.await();try{return action.call();}catch(BusinessException e){return e.getCode();}}));
            gate.countDown();return List.of(futures.get(0).get(20,TimeUnit.SECONDS),futures.get(1).get(20,TimeUnit.SECONDS));
        }
    }
}
