package com.skillbattles.backend;
import com.fasterxml.jackson.databind.*;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.processor.*;
import com.skillbattles.backend.service.*;
import com.skillbattles.backend.client.StripeBillingClient;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.*;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.context.annotation.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.*;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.*;
import java.net.*;
import java.net.http.*;
import java.nio.file.*;
import java.nio.charset.StandardCharsets;
import java.time.*;
import java.util.*;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import static com.skillbattles.backend.BattleFixtures.*;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.awaitility.Awaitility.await;

@SpringBootTest(webEnvironment=SpringBootTest.WebEnvironment.RANDOM_PORT,properties={"app.jwt.secret=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=","app.battle.scheduling.enabled=false","app.matchmaking.scheduling.enabled=false","app.realtime.monitor-ms=3600000","app.billing.webhook-secret=whsec_realtime_fixture","app.billing.monthly-price=price_m_fixture","app.billing.annual-price=price_a_fixture"})
@Import(BillingRealtimePostgresTest.Config.class) @Testcontainers(disabledWithoutDocker=true) @DirtiesContext(classMode=DirtiesContext.ClassMode.AFTER_CLASS)
class BillingRealtimePostgresTest {
    @Container static final PostgreSQLContainer<?> POSTGRES=new PostgreSQLContainer<>("postgres:17.12-alpine");
    @DynamicPropertySource static void database(DynamicPropertyRegistry r){r.add("spring.datasource.url",POSTGRES::getJdbcUrl);r.add("spring.datasource.username",POSTGRES::getUsername);r.add("spring.datasource.password",POSTGRES::getPassword);}
    @TestConfiguration static class Config {@Bean @Primary MutableClock testClock(){return new MutableClock();}}
    @LocalServerPort int port;@Autowired MutableClock clock;@Autowired AuthProcessor auth;@Autowired BattleProcessor processor;@Autowired BattleService battles;
    @Autowired SubscriptionService subscriptions;@Autowired BillingProcessor billing;@Autowired RealtimeSessionService sessions;@Autowired JdbcTemplate jdbc;
    @Autowired QuestionImportProcessor imports;@Autowired QuestionImportFileService files;@Autowired ObjectMapper json;@Autowired PlatformTransactionManager tx;
    @MockitoBean StripeBillingClient stripe;
    final HttpClient http=HttpClient.newHttpClient();final List<NativeStompClient> sockets=new ArrayList<>();
    @BeforeEach void setup() throws Exception {
        clock.set(START);jdbc.execute("TRUNCATE ranked_usage,battles,questions");uniformTiming(jdbc,60);
        imports.importQuestions(files.read(Path.of(Objects.requireNonNull(getClass().getResource("/fixtures/stage2-questions-test-only.json")).toURI())),false);
        when(stripe.available()).thenReturn(true);when(stripe.customer(any())).thenAnswer(c -> "cus_test_"+c.getArgument(0));
        when(stripe.checkout(any(),anyString(),anyString(),any())).thenAnswer(c -> new CheckoutDto("cs_test_"+c.getArgument(3),"https://checkout.stripe.com/test_fixture",clock.instant().plusSeconds(1800)));
    }
    @AfterEach void close(){sockets.forEach(NativeStompClient::close);sockets.clear();}
    @Test void realStompHasPersonalRedactionAccountChangesAndSameBattleVersionAfterDowngrade() throws Exception {
        var a=register();var b=register();var third=register();var sa=connect(a);var sb=connect(b);var sc=connect(third);
        UUID battle=processor.create(new CreateBattleDto(id(a),id(b),"SAT_MATH",BattleMode.PRIVATE));
        rest("POST","/api/v1/battles/"+battle+"/readiness",a,Map.of("ready",true),200);rest("POST","/api/v1/battles/"+battle+"/readiness",b,Map.of("ready",true),200);
        clock.set(START.plusSeconds(3));processor.tick(battle);sa.event(e -> phase(e,battle,"QUESTION"));sb.event(e -> phase(e,battle,"QUESTION"));
        checkout(a);var paid=state(a);when(stripe.latest(customer(a))).thenReturn(paid);webhook(a,"invoice.paid");
        var upgrade=sa.event(e -> account(e,a,true));assertThat(upgrade.path("data").path("user").path("id").asText()).isEqualTo(id(a).toString());
        assertThat(sb.hasEvent(e -> "ACCOUNT_CHANGED".equals(e.path("type").asText()),Duration.ofMillis(200))).isFalse();assertThat(sc.hasMessage(Duration.ofMillis(200))).isFalse();
        var raw=battles.lock(battle);var correct=answer(raw,true);
        rest("POST","/api/v1/battles/"+battle+"/answers",a,correct,200);
        var pending=sb.event(e -> phase(e,battle,"QUESTION")&&e.path("data").path("players").get(0).path("answeredCurrentRound").asBoolean());
        assertThat(pending.path("data").path("round").path("reveal").isNull()).isTrue();assertThat(pending.toString()).doesNotContain("correctOptionId","explanation");
        rest("POST","/api/v1/battles/"+battle+"/answers",b,answer(raw,false),200);
        var proReveal=sa.event(e -> phase(e,battle,"REVEAL"));var freeReveal=sb.event(e -> phase(e,battle,"REVEAL"));
        assertThat(proReveal.path("data").path("round").path("reveal").path("correctOptionId").asText()).isEqualTo(correct.getOptionId().toString());
        assertThat(freeReveal.path("data").path("round").path("reveal").path("correctOptionId").isNull()).isTrue();
        assertThat(freeReveal.path("data").path("round").path("reveal").path("answers").get(0).path("selectedOptionId").isNull()).isTrue();
        assertThat(proReveal.path("data").path("round").path("question").has("explanation")).isFalse();
        int version=proReveal.path("version").asInt();paid.setStatus("CANCELED");when(stripe.latest(customer(a))).thenReturn(paid);webhook(a,"customer.subscription.deleted");
        var downgrade=sa.event(e -> account(e,a,false));assertThat(downgrade.path("version").asInt()).isGreaterThan(upgrade.path("version").asInt());
        var fresh=rest("GET","/api/v1/battles/"+battle,a,null,200);assertThat(fresh.path("version").asInt()).isEqualTo(version);assertThat(fresh.path("round").path("reveal").path("correctOptionId").isNull()).isTrue();
        rest("POST","/api/v1/battles/"+battle+"/surrender",b,null,200);
        var review=rest("GET","/api/v1/battles/"+battle+"/review",a,null,200);assertThat(review.path("rounds").get(0).path("question").path("explanation").isNull()).isTrue();
        paid.setStatus("ACTIVE");paid.setSubscriptionId("sub_test_new_"+UUID.randomUUID());checkout(a);when(stripe.latest(customer(a))).thenReturn(paid);webhook(a,"invoice.paid");sa.event(e -> account(e,a,true));
        review=rest("GET","/api/v1/battles/"+battle+"/review",a,null,200);assertThat(review.path("rounds").get(0).path("question").path("explanation").asText()).startsWith("TEST ONLY");
        rest("GET","/api/v1/battles/"+battle+"/review",third,null,404);assertThat(sc.hasMessage(Duration.ofMillis(200))).isFalse();
    }
    @Test void accountEventsAreAfterCommitAndRollbackLeavesNoReceiptOrNotification() throws Exception {
        var a=register();var socket=connect(a);checkout(a);when(stripe.latest(customer(a))).thenReturn(state(a));var raw=event(a,"invoice.paid");String signature=sign(raw);
        assertThatThrownBy(() -> new TransactionTemplate(tx).execute(status -> {billing.webhook(raw,signature);try{assertThat(socket.hasEvent(e -> account(e,a,true),Duration.ofMillis(150))).isFalse();}catch(Exception ex){throw new AssertionError(ex);}throw new IllegalStateException("Test-only rollback");})).isInstanceOf(IllegalStateException.class);
        assertThat(subscriptions.entitlements(id(a)).isPro()).isFalse();assertThat(socket.hasEvent(e -> "ACCOUNT_CHANGED".equals(e.path("type").asText()),Duration.ofMillis(200))).isFalse();
        billing.webhook(raw,signature);socket.event(e -> account(e,a,true));
    }
    @Test void paidPeriodExpirySendsAccountChangedAndOldAccessJwtDoesNotKeepPro() throws Exception {
        var a=register();var socket=connect(a);checkout(a);var paid=state(a);paid.setCurrentPeriodEnd(clock.instant().plusSeconds(5));when(stripe.latest(customer(a))).thenReturn(paid);
        webhook(a,"invoice.paid");int version=socket.event(e -> account(e,a,true)).path("version").asInt();
        clock.set(paid.getCurrentPeriodEnd());subscriptions.expire();var expired=socket.event(e -> account(e,a,false));assertThat(expired.path("version").asInt()).isGreaterThan(version);
        var current=rest("GET","/api/v1/subscriptions/me",a,null,200);assertThat(current.path("status").asText()).isEqualTo("EXPIRED");assertThat(current.path("entitlements").path("isPro").asBoolean()).isFalse();
    }
    boolean phase(JsonNode e,UUID battle,String phase){return "BATTLE_CHANGED".equals(e.path("type").asText())&&battle.toString().equals(e.path("resourceId").asText())&&phase.equals(e.path("data").path("phase").asText());}
    boolean account(JsonNode e,AuthDto a,boolean pro){return "ACCOUNT_CHANGED".equals(e.path("type").asText())&&id(a).toString().equals(e.path("resourceId").asText())&&e.path("data").path("subscription").path("entitlements").path("isPro").asBoolean()==pro;}
    NativeStompClient connect(AuthDto a) throws Exception {var c=new NativeStompClient(http,URI.create("ws://localhost:"+port+"/ws/v1/events"),"http://localhost:"+port,json);sockets.add(c);c.connect(a.getTokens().getAccessToken());c.await("CONNECTED");c.startHeartbeats();c.subscribe("/user/queue/events");await().atMost(Duration.ofSeconds(5)).until(() -> sessions.current(id(a)).isPresent());return c;}
    JsonNode rest(String method,String path,AuthDto a,Object body,int expected) throws Exception {var request=HttpRequest.newBuilder(URI.create("http://localhost:"+port+path)).header("Authorization","Bearer "+a.getTokens().getAccessToken());if(body!=null)request.header("Content-Type","application/json");var response=http.send(request.method(method,body==null?HttpRequest.BodyPublishers.noBody():HttpRequest.BodyPublishers.ofString(json.writeValueAsString(body))).build(),HttpResponse.BodyHandlers.ofString());assertThat(response.statusCode()).isEqualTo(expected);assertThat(response.headers().firstValue("Cache-Control")).contains("no-store");return response.body().isBlank()?null:json.readTree(response.body());}
    void checkout(AuthDto a) throws Exception {rest("POST","/api/v1/subscriptions/checkout",a,new CheckoutRequest("PRO_MONTHLY",UUID.randomUUID()),200);}
    String customer(AuthDto a){return subscriptions.account(id(a)).getCustomerId();}
    ProviderSubscriptionDto state(AuthDto a){return new ProviderSubscriptionDto(customer(a),"sub_test_"+id(a),"price_m_fixture","ACTIVE",START,START.plusSeconds(3600),false,true,false);}
    byte[] event(AuthDto a,String type) throws Exception {return json.writeValueAsBytes(Map.of("id","evt_test_"+UUID.randomUUID(),"object","event","type",type,"livemode",false,"created",clock.instant().getEpochSecond(),"data",Map.of("object",Map.of("id","fixture_object","object","subscription","customer",customer(a),"livemode",false))));}
    String sign(byte[] raw) throws Exception {long time=clock.instant().getEpochSecond();var mac=Mac.getInstance("HmacSHA256");mac.init(new SecretKeySpec("whsec_realtime_fixture".getBytes(StandardCharsets.UTF_8),"HmacSHA256"));return "t="+time+",v1="+HexFormat.of().formatHex(mac.doFinal((time+"."+new String(raw,StandardCharsets.UTF_8)).getBytes(StandardCharsets.UTF_8)));}
    void webhook(AuthDto a,String type) throws Exception {var raw=event(a,type);var request=HttpRequest.newBuilder(URI.create("http://localhost:"+port+"/api/v1/subscriptions/webhook")).header("Content-Type","application/json").header("Stripe-Signature",sign(raw)).POST(HttpRequest.BodyPublishers.ofByteArray(raw)).build();assertThat(http.send(request,HttpResponse.BodyHandlers.discarding()).statusCode()).isEqualTo(204);}
    UUID id(AuthDto a){return a.getUser().getId();}
    AuthDto register(){var d=new RegisterDto();String s=UUID.randomUUID().toString().replace("-","").substring(0,12);d.setEmail(s+"@example.com");d.setNickname("BillWS_"+s);d.setPassword("ExamplePass123!");return auth.register(d);}
}
