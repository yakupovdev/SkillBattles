package com.skillbattles.backend;

import com.fasterxml.jackson.databind.*;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.exception.*;
import com.skillbattles.backend.processor.*;
import com.skillbattles.backend.service.*;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.*;
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
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.function.Supplier;
import static com.skillbattles.backend.BattleFixtures.*;
import static org.assertj.core.api.Assertions.*;
import static org.awaitility.Awaitility.await;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;

@SpringBootTest(webEnvironment=SpringBootTest.WebEnvironment.RANDOM_PORT,properties={
        "app.jwt.secret=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=","app.battle.scheduling.enabled=false",
        "app.matchmaking.scheduling.enabled=false","app.seasons.scheduling.enabled=false"})
@AutoConfigureMockMvc @Testcontainers(disabledWithoutDocker=true)
@Import(FriendsPostgresTest.Config.class) @DirtiesContext(classMode=DirtiesContext.ClassMode.AFTER_CLASS)
class FriendsPostgresTest {
    @Container static final PostgreSQLContainer<?> POSTGRES=new PostgreSQLContainer<>("postgres:17.12-alpine");
    @DynamicPropertySource static void database(DynamicPropertyRegistry r){r.add("spring.datasource.url",POSTGRES::getJdbcUrl);r.add("spring.datasource.username",POSTGRES::getUsername);r.add("spring.datasource.password",POSTGRES::getPassword);}
    @TestConfiguration static class Config {
        @Bean @Primary MutableClock friendClock(){return new MutableClock();}
        @Bean Changes socialChanges(){return new Changes();}
    }
    static class Changes {
        final List<Object> events=new CopyOnWriteArrayList<>();
        @EventListener public void friendship(FriendshipChangedEvent e){events.add(e);}
        @EventListener public void invitation(DuelInvitationChangedEvent e){events.add(e);}
    }
    @Autowired FriendProcessor friends;
    @Autowired DuelInvitationProcessor invitations;
    @Autowired MatchmakingProcessor matchmaking;
    @Autowired MatchmakingRegistryService registry;
    @Autowired AuthProcessor auth;
    @MockitoSpyBean UserService users;
    @MockitoSpyBean SubscriptionService subscriptions;
    @MockitoSpyBean FriendCodeGenerator codes;
    @MockitoSpyBean BattleProcessor battle;
    @MockitoSpyBean DuelInvitationReconciler reconciliation;
    @MockitoSpyBean FriendPresentationProcessor presentation;
    @Autowired FriendRelationService relations;
    @Autowired MutableClock clock;
    @Autowired JdbcTemplate jdbc;
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired Changes changes;
    @Autowired RealtimeSessionService sessions;
    @Autowired PlatformTransactionManager transactions;
    @LocalServerPort int port;
    final List<NativeStompClient> clients=new ArrayList<>();
    HttpClient http;
    @BeforeEach void setup(){clock.set(START);registry.transact(s->{s.getEntries().clear();s.getDuels().clear();s.getActivities().clear();s.getRematches().clear();s.getDuelInvitations().clear();s.getInvitationReceipts().clear();return null;});jdbc.execute("TRUNCATE friend_relations,question_reports,ranked_usage,battles");changes.events.clear();http=HttpClient.newHttpClient();}
    @AfterEach void cleanup(){clients.forEach(NativeStompClient::close);await().atMost(Duration.ofSeconds(5)).until(()->!sessions.hasSubscribers());http.close();}

    @Test void ownCodeNormalizationLazyAllocationAndWholeTransactionCollisionRetry()throws Exception{
        var a=register();var b=register();String first=friends.code(id(a)).friendCode();
        assertThat(first).matches("[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{12}");assertThat(friends.code(id(a)).friendCode()).isEqualTo(first);
        jdbc.update("UPDATE users SET friend_code=NULL WHERE id=?",id(b));
        doReturn(first,"ZZZZZZZZZZZY").when(codes).next();
        assertThat(friends.code(id(b)).friendCode()).isEqualTo("ZZZZZZZZZZZY");
        doReturn(first,"ZZZZZZZZZZZX").when(codes).next();
        var c=register();assertThat(friends.code(id(c)).friendCode()).isEqualTo("ZZZZZZZZZZZX");
        assertThat(jdbc.queryForObject("SELECT count(*) FROM ratings WHERE user_id=?",Integer.class,id(c))).isEqualTo(2);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM refresh_tokens WHERE user_id=?",Integer.class,id(c))).isEqualTo(1);
        var sent=friends.send(id(a)," "+friends.code(id(b)).friendCode().toLowerCase(Locale.ROOT).replaceAll("(.{4})(?=.)","$1-")+" ");
        assertThat(sent.created()).isTrue();assertThat(sent.value().recipient().getId()).isEqualTo(id(b));
        rest("GET","/api/v1/users/me/friend-code",null,null,401);
        rest("GET","/api/v1/users/me/friend-code",a.getTokens().getRefreshToken(),null,401);
        assertThat(rest("GET","/api/v1/users/me",a,null,200).has("friendCode")).isFalse();
    }
    @Test void deletedAccountsCodesAreNeverReused(){var a=register();String code=friends.code(id(a)).friendCode();users.softDelete(id(a));doReturn(code,"ZZZZZZZZZZZW").when(codes).next();var b=register();assertThat(friends.code(id(b)).friendCode()).isEqualTo("ZZZZZZZZZZZW");}

    @Test void friendRequestLifecycleRolesPrivacyCooldownAndFreshIdentity()throws Exception{
        var a=register();var b=register();var c=register();var created=send(a,b);UUID request=created.value().id();int count=changes.events.size();
        assertThat(send(a,b).created()).isFalse();assertThat(changes.events).hasSize(count);
        rest("POST","/api/v1/friend-requests",b,Map.of("friendCode",friends.code(id(a)).friendCode()),409);
        rest("GET","/api/v1/friend-requests/"+request,c,null,404);rest("POST","/api/v1/friend-requests/"+request+"/accept",a,null,403);
        rest("DELETE","/api/v1/friend-requests/"+request,b,null,403);
        var declined=friends.respond(id(b),request,FriendStatus.DECLINED);assertThat(friends.respond(id(b),request,FriendStatus.DECLINED)).isEqualTo(declined);
        assertThatThrownBy(()->send(a,b)).isInstanceOf(RateLimitedException.class);
        clock.set(START.plusSeconds(60).minusNanos(1));assertThatThrownBy(()->send(a,b)).isInstanceOf(RateLimitedException.class);
        clock.set(START.plusSeconds(60));var next=send(a,b).value();assertThat(next.id()).isNotEqualTo(request);assertThat(next.version()).isEqualTo(1);
        var accepted=friends.respond(id(b),next.id(),FriendStatus.ACCEPTED);assertThat(friends.respond(id(b),next.id(),FriendStatus.ACCEPTED)).isEqualTo(accepted);
        assertThat(friends.friends(id(a),0,20).data()).hasSize(1);assertThat(friends.requests(id(b),FriendRequestDirection.INCOMING,0,20).data()).isEmpty();
        rest("DELETE","/api/v1/friend-requests/"+next.id(),a,null,409);
        friends.remove(id(b),id(a));friends.remove(id(b),id(a));assertThat(friends.get(id(a),next.id()).status()).isEqualTo(FriendStatus.REMOVED);
        rest("GET","/api/v1/friends/"+id(b),a,null,404);
        clock.set(START.plusSeconds(120));assertThat(send(a,b).value().id()).isNotEqualTo(next.id());
    }
    @Test void requestValidationAndLimiterDoNotBlockReadsOrAccept()throws Exception{
        var a=register();var b=register();var request=send(b,a).value();
        for(String code:List.of("abc","A BCD2345EFGH","ＡBCD2345EFGH","ABCD2345EFGI","\u0000ABCD2345EFGH","A".repeat(33)))rest("POST","/api/v1/friend-requests",a,Map.of("friendCode",code),400);
        rest("POST","/api/v1/friend-requests",a,Map.of("friendCode",friends.code(id(a)).friendCode()),409);
        for(int i=0;i<25;i++){try{friends.send(id(a),"YYYYYYYYYYYY");}catch(BusinessException ignored){}}
        var limited=rest("POST","/api/v1/friend-requests",a,Map.of("friendCode","YYYYYYYYYYYY"),429);assertThat(limited.path("code").asText()).isEqualTo("RATE_LIMITED");
        friends.respond(id(a),request.id(),FriendStatus.ACCEPTED);assertThat(friends.friends(id(a),0,20).data()).hasSize(1);
        for(String query:List.of("page=-1","size=0","size=101","page=nope","direction=incoming"))rest("GET","/api/v1/friend-requests?"+query,a,null,400);
    }
    @Test void paginationUsesOneMetadataBatchAndFiltersDeletedAccounts(){
        var a=register();List<AuthDto> others=new ArrayList<>();for(int i=0;i<4;i++){var b=register();others.add(b);makeFriends(a,b);clock.set(clock.instant().plusSeconds(1));}
        clearInvocations(users,subscriptions);
        var page=friends.friends(id(a),1,2);assertThat(page.data()).hasSize(2);assertThat(page.pagination().getTotalElements()).isEqualTo(4);
        verify(users,times(1)).findByIds(anyCollection());verify(subscriptions,times(1)).proFlags(anyCollection());
        users.softDelete(id(others.getFirst()));assertThat(friends.friends(id(a),0,20).data()).hasSize(3);
        assertThat(friends.friends(id(a),9,2).data()).isEmpty();
    }
    @ParameterizedTest @CsvSource({"false,false","false,true","true,false","true,true"})
    void friendProfileIsBasicForEveryPlanCombination(boolean viewerPro,boolean targetPro)throws Exception{
        var a=register();var b=register();makeFriends(a,b);if(viewerPro)grant(a);if(targetPro)grant(b);
        var profile=rest("GET","/api/v1/friends/"+id(b),a,null,200);
        assertThat(fields(profile)).containsExactlyInAnyOrder("friend","friendsSince","disciplines");
        assertThat(profile.path("friend").path("isPro").asBoolean()).isEqualTo(targetPro);
        for(var discipline:profile.path("disciplines")){
            assertThat(fields(discipline)).containsExactlyInAnyOrder("disciplineCode","rating","rank","calibration","allTimePeakRating","allTimePeakRankCode","seasonId","seasonPeakRating","seasonPeakRankCode","seasonRolloverPending","ranked","privateMatches");
            for(String kind:List.of("ranked","privateMatches")){assertThat(discipline.path(kind).path("played").asInt()).isZero();for(String nullable:List.of("winRatePercent","accuracyPercent","avgAnswerTimeMs"))assertThat(discipline.path(kind).path(nullable).isNull()).isTrue();}
        }
        assertThat(profile.toString()).doesNotContain("email","friendCode","birthYear","entitlements","topicStats","ratingHistory","streakCalendar");
        friends.remove(id(a),id(b));rest("GET","/api/v1/friends/"+id(b),a,null,404);
    }
    @Test void crossedRequestsAndConcurrentAcceptsProduceOneLivePair()throws Exception{
        var a=register();var b=register();race(()->send(a,b),()->send(b,a));
        assertThat(jdbc.queryForObject("SELECT count(*) FROM friend_relations WHERE status='PENDING'",Integer.class)).isEqualTo(1);
        var r=relations.pair(FriendPair.of(id(a),id(b))).getFirst();race(()->friends.respond(r.recipientId(),r.id(),FriendStatus.ACCEPTED),()->friends.respond(r.recipientId(),r.id(),FriendStatus.ACCEPTED));
        assertThat(relations.get(r.id()).version()).isEqualTo(2);
        assertThatThrownBy(()->jdbc.update("INSERT INTO friend_relations SELECT gen_random_uuid(),created_at,updated_at,deleted,user_low_id,user_high_id,requester_id,recipient_id,status,accepted_at,version FROM friend_relations WHERE id=?",r.id())).hasStackTraceContaining("ux_friend_live_pair");
    }
    @Test void inviteIsHostOnlyPersonalIdempotentAndJoinsExactlyTheExistingRoom()throws Exception{
        var a=register();var b=register();var c=register();makeFriends(a,b);makeFriends(a,c);
        var room=matchmaking.createDuel(id(a),"SAT_MATH");UUID request=UUID.randomUUID();var sent=invitations.send(id(a),room.getId(),id(b),request);var invite=sent.value();
        assertThat(sent.created()).isTrue();assertThat(matchmaking.activity(id(b)).getType()).isEqualTo(ActivityType.NONE);
        int changesBefore=changes.events.size();assertThat(invitations.send(id(a),room.getId(),id(b),request).value()).isEqualTo(invite);assertThat(changes.events).hasSize(changesBefore);
        UUID alias=UUID.randomUUID();assertThat(invitations.send(id(a),room.getId(),id(b),alias).created()).isFalse();
        assertThatThrownBy(()->invitations.send(id(a),room.getId(),id(c),alias)).hasMessageContaining("requestId");
        rest("POST","/api/v1/duels/"+room.getId()+"/invitations",a,Map.of("friendId",id(c),"requestId",UUID.randomUUID()),409);
        rest("GET","/api/v1/duels/"+room.getId(),b,null,404);rest("GET","/api/v1/duels/"+room.getId()+"/invitations",b,null,404);
        rest("GET","/api/v1/duel-invitations/"+invite.id(),c,null,404);rest("POST","/api/v1/duel-invitations/"+invite.id()+"/accept",a,null,403);
        var accepted=invitations.accept(id(b),invite.id());assertThat(accepted.duelId()).isEqualTo(room.getId());assertThat(accepted.battleId()).isNotNull();
        assertThat(invitations.accept(id(b),invite.id())).isEqualTo(accepted);assertThat(matchmaking.duel(id(a),room.getId()).getBattleId()).isEqualTo(accepted.battleId());
        assertThat(invitations.incoming(id(b)).data()).isEmpty();assertThat(battle.snapshot(accepted.battleId(),id(b)).getPhase()).isEqualTo(BattlePhase.WAITING_READY);
        rest("DELETE","/api/v1/duel-invitations/"+invite.id(),a,null,409);rest("POST","/api/v1/duel-invitations/"+invite.id()+"/decline",b,null,409);
        battle.surrender(accepted.battleId(),id(a));assertThat(invitations.accept(id(b),invite.id()).battleId()).isEqualTo(accepted.battleId());
        clock.set(room.getExpiresAt().plusSeconds(1));
        assertThatThrownBy(()->invitations.send(id(a),room.getId(),id(b),UUID.randomUUID())).isInstanceOf(ConflictException.class);
        assertThat(invitations.accept(id(b),invite.id()).battleId()).isEqualTo(accepted.battleId());
    }
    @ParameterizedTest @ValueSource(strings={"QUEUE","DUEL","BATTLE"})
    void busyRecipientCanReceiveAndDeclineWithoutLosingActivity(String kind){
        var a=register();var b=register();var c=register();makeFriends(a,b);var room=matchmaking.createDuel(id(a),"SAT_MATH");
        if(kind.equals("QUEUE"))matchmaking.search(id(b),"SAT_RW");else if(kind.equals("DUEL"))matchmaking.createDuel(id(b),"SAT_RW");else battle.create(new CreateBattleDto(id(b),id(c),"SAT_RW",BattleMode.PRIVATE));
        var activity=matchmaking.activity(id(b));var i=invitations.send(id(a),room.getId(),id(b),UUID.randomUUID()).value();
        assertThatThrownBy(()->invitations.accept(id(b),i.id())).isInstanceOf(ConflictException.class);
        assertThat(invitations.get(id(b),i.id()).status()).isEqualTo(DuelInvitationStatus.PENDING);assertThat(matchmaking.activity(id(b))).isEqualTo(activity);
        assertThat(invitations.decline(id(b),i.id()).status()).isEqualTo(DuelInvitationStatus.DECLINED);assertThat(matchmaking.activity(id(b))).isEqualTo(activity);assertThat(matchmaking.duel(id(a),room.getId()).getStatus()).isEqualTo(DuelStatus.WAITING);
    }
    @Test void exactInviteAndRoomDeadlinesHavePriorityAndNeverRenew(){
        var a=register();var b=register();makeFriends(a,b);var room=matchmaking.createDuel(id(a),"SAT_MATH");UUID request=UUID.randomUUID();var i=invitations.send(id(a),room.getId(),id(b),request).value();
        clock.set(i.expiresAt().minusNanos(1));assertThat(invitations.incoming(id(b)).data()).hasSize(1);assertThat(invitations.send(id(a),room.getId(),id(b),request).value().expiresAt()).isEqualTo(i.expiresAt());
        clock.set(i.expiresAt());assertThat(invitations.incoming(id(b)).data()).isEmpty();assertThat(invitations.get(id(b),i.id()).reason()).isEqualTo(DuelInvitationReason.INVITATION_EXPIRED);
        assertThatThrownBy(()->invitations.accept(id(b),i.id())).isInstanceOf(GoneException.class);assertThat(matchmaking.duel(id(a),room.getId()).getStatus()).isEqualTo(DuelStatus.WAITING);
        clock.set(i.expiresAt().plusSeconds(60).minusNanos(1));assertThatThrownBy(()->invitations.send(id(a),room.getId(),id(b),UUID.randomUUID())).isInstanceOf(RateLimitedException.class);
        clock.set(i.expiresAt().plusSeconds(60));registry.transact(s->{s.getDuels().put(room.getId(),s.getDuels().get(room.getId()).toBuilder().expiresAt(clock.instant().plusSeconds(10)).build());return null;});
        var capped=invitations.send(id(a),room.getId(),id(b),UUID.randomUUID()).value();assertThat(capped.expiresAt()).isEqualTo(clock.instant().plusSeconds(10));clock.set(capped.expiresAt());assertThat(invitations.get(id(b),capped.id()).reason()).isEqualTo(DuelInvitationReason.DUEL_EXPIRED);
    }
    @ParameterizedTest @ValueSource(strings={"WITHDRAW","DECLINE","CANCEL_ROOM","UNFRIEND","OTHER_JOIN","FRIEND_JOIN"})
    void allRoomTransitionsReconcileInvitations(String action){
        var a=register();var b=register();var c=register();makeFriends(a,b);var room=matchmaking.createDuel(id(a),"SAT_MATH");var i=invitations.send(id(a),room.getId(),id(b),UUID.randomUUID()).value();
        switch(action){case "WITHDRAW"->invitations.withdraw(id(a),i.id());case "DECLINE"->invitations.decline(id(b),i.id());case "CANCEL_ROOM"->matchmaking.cancelDuel(id(a),room.getId());case "UNFRIEND"->friends.remove(id(b),id(a));case "OTHER_JOIN"->matchmaking.join(id(c),room.getCode());case "FRIEND_JOIN"->matchmaking.join(id(b),room.getCode());}
        var result=invitations.get(id(b),i.id());
        assertThat(result.status()).isEqualTo(action.equals("FRIEND_JOIN")?DuelInvitationStatus.ACCEPTED:action.equals("DECLINE")?DuelInvitationStatus.DECLINED:DuelInvitationStatus.CANCELLED);
        if(action.equals("OTHER_JOIN")){assertThat(result.reason()).isEqualTo(DuelInvitationReason.DUEL_FILLED);assertThat(result.battleId()).isNull();}
        if(!action.endsWith("JOIN")&&!action.equals("CANCEL_ROOM"))assertThat(matchmaking.duel(id(a),room.getId()).getStatus()).isEqualTo(DuelStatus.WAITING);
    }
    @ParameterizedTest @ValueSource(strings={"ACCEPT","CODE_JOIN","CANCEL","UNFRIEND","EXPIRY"})
    void acceptRacesCommitAtMostOneBattle(String action)throws Exception{
        var a=register();var b=register();makeFriends(a,b);var room=matchmaking.createDuel(id(a),"SAT_MATH");var i=invitations.send(id(a),room.getId(),id(b),UUID.randomUUID()).value();
        Supplier<Object> other=switch(action){case "ACCEPT"->()->invitations.accept(id(b),i.id());case "CODE_JOIN"->()->matchmaking.join(id(b),room.getCode());case "CANCEL"->()->{matchmaking.cancelDuel(id(a),room.getId());return null;};case "UNFRIEND"->()->{friends.remove(id(a),id(b));return null;};default->()->{clock.set(i.expiresAt());return invitations.get(id(b),i.id());};};
        race(()->invitations.accept(id(b),i.id()),other);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM battles",Integer.class)).isBetween(0,1);
        var result=invitations.get(id(b),i.id());if(result.status()==DuelInvitationStatus.ACCEPTED)assertThat(result.battleId()).isNotNull();else assertThat(result.battleId()).isNull();
    }
    @Test void battleWriteRollbackPreservesRoomInvitationReservationAndSuppressesEvents(){
        var a=register();var b=register();makeFriends(a,b);var room=matchmaking.createDuel(id(a),"SAT_MATH");var i=invitations.send(id(a),room.getId(),id(b),UUID.randomUUID()).value();changes.events.clear();
        doAnswer(call->{call.callRealMethod();throw new IllegalStateException("TEST ONLY after battle write");}).when(battle).create(any(CreateBattleDto.class));
        assertThatThrownBy(()->invitations.accept(id(b),i.id())).isInstanceOf(IllegalStateException.class);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM battles",Integer.class)).isZero();assertThat(invitations.get(id(b),i.id()).status()).isEqualTo(DuelInvitationStatus.PENDING);
        assertThat(matchmaking.activity(id(a)).getType()).isEqualTo(ActivityType.PRIVATE_DUEL);assertThat(matchmaking.activity(id(b)).getType()).isEqualTo(ActivityType.NONE);assertThat(changes.events).isEmpty();
    }
    @Test void unfriendRollbackKeepsPersistentRelationAndStagedInvitation(){
        var a=register();var b=register();var r=makeFriends(a,b);var room=matchmaking.createDuel(id(a),"SAT_MATH");var i=invitations.send(id(a),room.getId(),id(b),UUID.randomUUID()).value();changes.events.clear();
        doAnswer(call->{call.callRealMethod();throw new IllegalStateException("TEST ONLY reconciliation failure");}).when(reconciliation).refresh(any(),any());
        assertThatThrownBy(()->friends.remove(id(a),id(b))).isInstanceOf(IllegalStateException.class);
        doCallRealMethod().when(reconciliation).refresh(any(),any());assertThat(relations.get(r.id()).status()).isEqualTo(FriendStatus.ACCEPTED);assertThat(invitations.get(id(b),i.id()).status()).isEqualTo(DuelInvitationStatus.PENDING);assertThat(changes.events).isEmpty();
    }
    @Test void realStompUsesOnlyCurrentPersonalSessionsAfterCommitAndNotOnRollback()throws Exception{
        var a=register();var b=register();var c=register();var sa=connect(a);var sb=connect(b);var sc=connect(c);
        var request=send(a,b).value();var event=sb.event(e->e.path("type").asText().equals("FRIENDSHIP_CHANGED"));assertThat(event.path("resourceId").asText()).isEqualTo(request.id().toString());assertThat(event.path("version")).isEqualTo(event.path("data").path("version"));
        sa.event(e->e.path("type").asText().equals("FRIENDSHIP_CHANGED"));assertThat(sc.hasMessage(Duration.ofMillis(150))).isFalse();
        friends.respond(id(b),request.id(),FriendStatus.ACCEPTED);sa.event(e->e.path("data").path("status").asText().equals("ACCEPTED"));sb.event(e->e.path("data").path("status").asText().equals("ACCEPTED"));
        sa.drain();sb.drain();sendAlreadyAccepted(a,b);assertThat(sb.hasMessage(Duration.ofMillis(150))).isFalse();
        var replacement=connect(b);sb.closed.get(5,TimeUnit.SECONDS);
        var room=matchmaking.createDuel(id(a),"SAT_MATH");var invite=invitations.send(id(a),room.getId(),id(b),UUID.randomUUID()).value();
        var notification=replacement.event(e->e.path("type").asText().equals("DUEL_INVITATION_CHANGED"));assertThat(notification.path("data").path("id").asText()).isEqualTo(invite.id().toString());assertThat(notification.toString()).doesNotContain("friendCode","email","code\"");assertThat(sc.hasMessage(Duration.ofMillis(150))).isFalse();
        replacement.drain();new TransactionTemplate(transactions).executeWithoutResult(status->{registry.transact(state->{var i=state.getDuelInvitations().get(invite.id());state.getDuelInvitations().put(i.getId(),i.toBuilder().status(DuelInvitationStatus.DECLINED).version(2).build());return null;});status.setRollbackOnly();});
        assertThat(replacement.hasMessage(Duration.ofMillis(150))).isFalse();assertThat(invitations.get(id(b),invite.id()).status()).isEqualTo(DuelInvitationStatus.PENDING);
    }

    @Test void migrationUpgradePreservesUsersQuestionsRatingsAndExistingHistory(){
        String schema="friends_upgrade";var old=Flyway.configure().dataSource(POSTGRES.getJdbcUrl(),POSTGRES.getUsername(),POSTGRES.getPassword()).schemas(schema).target("14").load();old.migrate();
        var beforeUsers=jdbc.queryForList("SELECT to_jsonb(u)::text AS value FROM friends_upgrade.users u ORDER BY id");
        var beforeQuestions=jdbc.queryForList("SELECT to_jsonb(q)::text FROM friends_upgrade.questions q ORDER BY id");
        var beforeRatings=jdbc.queryForList("SELECT to_jsonb(r)::text FROM friends_upgrade.ratings r ORDER BY id");
        var beforeHistory=jdbc.queryForList("SELECT version,checksum FROM friends_upgrade.flyway_schema_history ORDER BY installed_rank");
        var latest=Flyway.configure().dataSource(POSTGRES.getJdbcUrl(),POSTGRES.getUsername(),POSTGRES.getPassword()).schemas(schema).load();assertThat(latest.migrate().migrationsExecuted).isEqualTo(1);
        assertThat(jdbc.queryForList("SELECT (to_jsonb(u)-'friend_code')::text AS value FROM friends_upgrade.users u ORDER BY id")).isEqualTo(beforeUsers);
        assertThat(jdbc.queryForList("SELECT to_jsonb(q)::text FROM friends_upgrade.questions q ORDER BY id")).isEqualTo(beforeQuestions);
        assertThat(jdbc.queryForList("SELECT to_jsonb(r)::text FROM friends_upgrade.ratings r ORDER BY id")).isEqualTo(beforeRatings);
        assertThat(jdbc.queryForList("SELECT version,checksum FROM friends_upgrade.flyway_schema_history WHERE version IS NULL OR version::int<=14 ORDER BY installed_rank")).isEqualTo(beforeHistory);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM friends_upgrade.friend_relations",Integer.class)).isZero();assertThat(latest.migrate().migrationsExecuted).isZero();latest.validate();
        var ids=jdbc.queryForList("SELECT id FROM friends_upgrade.users ORDER BY id",UUID.class);UUID low=ids.get(0),high=ids.get(1);
        assertThat(low.toString().compareTo(high.toString())).isNegative();
        assertThatThrownBy(()->jdbc.update("INSERT INTO friends_upgrade.friend_relations(id,created_at,updated_at,user_low_id,user_high_id,requester_id,recipient_id,status,version) VALUES(gen_random_uuid(),now(),now(),?,?,?,?, 'PENDING',1)",high,low,high,low)).hasStackTraceContaining("ck_friend_pair");
        assertThatThrownBy(()->jdbc.update("INSERT INTO friends_upgrade.friend_relations(id,created_at,updated_at,user_low_id,user_high_id,requester_id,recipient_id,status,version) VALUES(gen_random_uuid(),now(),now(),?,?,?,?, 'PENDING',1)",low,high,low,low)).hasStackTraceContaining("ck_friend_direction");
    }
    @Test void incomingListsBatchMetadataAndRoomReceiptsStayBoundAfterResolution(){
        var a=register();var b=register();var c=register();makeFriends(a,b);makeFriends(c,b);var roomA=matchmaking.createDuel(id(a),"SAT_MATH");var roomC=matchmaking.createDuel(id(c),"SAT_MATH");
        UUID original=UUID.randomUUID(),alias=UUID.randomUUID();var one=invitations.send(id(a),roomA.getId(),id(b),original).value();invitations.send(id(a),roomA.getId(),id(b),alias);invitations.send(id(c),roomC.getId(),id(b),UUID.randomUUID());
        clearInvocations(users,subscriptions);assertThat(invitations.incoming(id(b)).data()).hasSize(2);verify(users,times(1)).findByIds(anyCollection());verify(subscriptions,times(1)).proFlags(anyCollection());
        invitations.withdraw(id(a),one.id());assertThat(invitations.send(id(a),roomA.getId(),id(b),alias).value().status()).isEqualTo(DuelInvitationStatus.CANCELLED);
        assertThatThrownBy(()->invitations.send(id(a),roomA.getId(),id(b),UUID.randomUUID())).isInstanceOf(RateLimitedException.class);
        assertThatThrownBy(()->invitations.send(id(a),UUID.randomUUID(),id(b),alias)).isInstanceOf(ConflictException.class);
    }
    @Test void invitationNewSendLimiterDoesNotCountIdempotentReceiptsOrBlockDecline(){
        var a=register();var b=register();makeFriends(a,b);DuelDto room=null;UUID lastRequest=null;DuelInvitationViewDto last=null;
        for(int i=0;i<30;i++){room=matchmaking.createDuel(id(a),"SAT_MATH");lastRequest=UUID.randomUUID();last=invitations.send(id(a),room.getId(),id(b),lastRequest).value();for(int retry=0;retry<2;retry++)assertThat(invitations.send(id(a),room.getId(),id(b),lastRequest).created()).isFalse();if(i<29)matchmaking.cancelDuel(id(a),room.getId());}
        assertThat(invitations.decline(id(b),last.id()).status()).isEqualTo(DuelInvitationStatus.DECLINED);matchmaking.cancelDuel(id(a),room.getId());var next=matchmaking.createDuel(id(a),"SAT_MATH");
        assertThatThrownBy(()->invitations.send(id(a),next.getId(),id(b),UUID.randomUUID())).isInstanceOf(RateLimitedException.class);assertThat(invitations.incoming(id(b)).data()).isEmpty();
    }
    @Test void profileAndRemovalUseCompatibleCanonicalLocks()throws Exception{
        var a=register();var b=register();var r=makeFriends(a,b);race(()->friends.profile(id(a),id(b)),()->{friends.remove(id(b),id(a));return null;});
        assertThat(relations.get(r.id()).status()).isEqualTo(FriendStatus.REMOVED);assertThatThrownBy(()->friends.profile(id(a),id(b))).isInstanceOf(NotFoundException.class);
    }
    @Test void accountDeletionBetweenListAndMetadataNeverProducesNullPublicPlayers(){
        var a=register();var b=register();makeFriends(a,b);var room=matchmaking.createDuel(id(a),"SAT_MATH");var invitation=invitations.send(id(a),room.getId(),id(b),UUID.randomUUID()).value();
        var deleted=new java.util.concurrent.atomic.AtomicBoolean();
        doAnswer(call->{if(deleted.compareAndSet(false,true))CompletableFuture.runAsync(()->users.softDelete(id(b))).get(5,TimeUnit.SECONDS);return call.callRealMethod();}).when(presentation).players(anyCollection());
        assertThat(friends.friends(id(a),0,20).data()).isEmpty();
        assertThat(invitations.incoming(id(b)).data()).isEmpty();
        assertThatThrownBy(()->invitations.get(id(a),invitation.id())).isInstanceOf(NotFoundException.class);
    }
    @Test void battleCreationAndFriendProfileUsePostgresUuidOrderAcrossTheSignBit()throws Exception{
        UUID low=UUID.fromString("00000000-0000-4000-8000-000000000015"),high=UUID.fromString("ffffffff-ffff-4fff-8fff-ffffffff0015");
        for(UUID id:List.of(low,high))jdbc.update("INSERT INTO users(id,created_at,updated_at,email_normalized,nickname,nickname_normalized,password_hash) VALUES(?,now(),now(),?,?,?,'test-only-hash')",id,id+"@example.com","Fixed_"+id.toString().substring(0,8),"fixed_"+id.toString().substring(0,8));
        assertThat(low.compareTo(high)).isPositive();assertThat(low.toString().compareTo(high.toString())).isNegative();
        var request=friends.send(low,users.friendCode(high)).value();friends.respond(high,request.id(),FriendStatus.ACCEPTED);
        clearInvocations(users);UUID created=battle.create(new CreateBattleDto(high,low,"SAT_MATH",BattleMode.PRIVATE));
        var order=inOrder(users);order.verify(users).lockActiveById(low);order.verify(users).lockActiveById(high);
        battle.surrender(created,low);
        race(()->friends.profile(low,high),()->battle.create(new CreateBattleDto(high,low,"SAT_MATH",BattleMode.PRIVATE)));
        assertThat(jdbc.queryForObject("SELECT count(*) FROM battles",Integer.class)).isEqualTo(2);
    }

    private AuthDto register(){var r=new RegisterDto();r.setBirthYear(2000);r.setBirthMonth(1);String suffix=UUID.randomUUID().toString().replace("-","").substring(0,12);r.setEmail(suffix+"@example.com");r.setNickname("Friend_"+suffix);r.setPassword("ExamplePass123!");return auth.register(r);}
    private UUID id(AuthDto a){return a.getUser().getId();}
    private SocialCommandDto<RelationshipDto> send(AuthDto a,AuthDto b){return friends.send(id(a),friends.code(id(b)).friendCode());}
    private RelationshipDto makeFriends(AuthDto a,AuthDto b){return friends.respond(id(b),send(a,b).value().id(),FriendStatus.ACCEPTED);}
    private void sendAlreadyAccepted(AuthDto a,AuthDto b){assertThatThrownBy(()->send(a,b)).isInstanceOf(ConflictException.class);}
    private void grant(AuthDto user){String customer="cus_test_"+id(user);subscriptions.bindCustomer(id(user),customer);subscriptions.apply(id(user),"evt_test_"+UUID.randomUUID(),new ProviderSubscriptionDto(customer,"sub_test_"+id(user),"price_test","ACTIVE",START.minusSeconds(1),START.plusSeconds(86400),false,true,false),"PRO_MONTHLY");}
    private Set<String> fields(JsonNode node){var set=new HashSet<String>();node.fieldNames().forEachRemaining(set::add);return set;}
    private JsonNode rest(String method,String path,Object user,Object body,int expected)throws Exception{var r=request(org.springframework.http.HttpMethod.valueOf(method),path);if(user!=null)r.header("Authorization","Bearer "+(user instanceof AuthDto a?a.getTokens().getAccessToken():user));if(body!=null)r.contentType("application/json").content(json.writeValueAsBytes(body));var response=mvc.perform(r).andReturn().getResponse();assertThat(response.getStatus()).as(method+" "+path+" "+response.getContentAsString()).isEqualTo(expected);assertThat(response.getHeader("Cache-Control")).isEqualTo("no-store");return response.getContentAsByteArray().length==0?json.nullNode():json.readTree(response.getContentAsString());}
    private List<Object> race(Supplier<Object> first,Supplier<Object> second)throws Exception{try(var pool=Executors.newFixedThreadPool(2)){var start=new CountDownLatch(1);var a=pool.submit(()->{start.await();try{return first.get();}catch(BusinessException e){return e.getCode();}});var b=pool.submit(()->{start.await();try{return second.get();}catch(BusinessException e){return e.getCode();}});start.countDown();return Arrays.asList(a.get(15,TimeUnit.SECONDS),b.get(15,TimeUnit.SECONDS));}}
    private NativeStompClient connect(AuthDto a)throws Exception{var c=new NativeStompClient(http,URI.create("ws://localhost:"+port+"/ws/v1/events"),"http://localhost:"+port,json);clients.add(c);c.connect(a.getTokens().getAccessToken());c.await("CONNECTED");c.startHeartbeats();c.subscribe("/user/queue/events");await().atMost(Duration.ofSeconds(5)).until(()->sessions.current(id(a)).isPresent());return c;}
}
