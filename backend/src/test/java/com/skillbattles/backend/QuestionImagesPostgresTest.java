package com.skillbattles.backend;

import com.fasterxml.jackson.databind.*;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.exception.*;
import com.skillbattles.backend.mapper.*;
import com.skillbattles.backend.processor.*;
import com.skillbattles.backend.service.*;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.*;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.context.annotation.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.*;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.*;
import javax.imageio.ImageIO;
import java.io.ByteArrayInputStream;
import java.net.URI;
import java.net.http.*;
import java.security.MessageDigest;
import java.time.*;
import java.util.*;
import static com.skillbattles.backend.BattleFixtures.*;
import static org.assertj.core.api.Assertions.*;
import static org.awaitility.Awaitility.await;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {
        "app.jwt.secret=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=", "app.battle.scheduling.enabled=false",
        "app.matchmaking.scheduling.enabled=false", "app.seasons.scheduling.enabled=false"})
@AutoConfigureMockMvc
@Testcontainers(disabledWithoutDocker = true)
@Import(QuestionImagesPostgresTest.Config.class)
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
class QuestionImagesPostgresTest {
    @Container static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:17.12-alpine");
    @DynamicPropertySource static void database(DynamicPropertyRegistry r) {
        r.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        r.add("spring.datasource.username", POSTGRES::getUsername);
        r.add("spring.datasource.password", POSTGRES::getPassword);
    }
    @TestConfiguration static class Config {
        @Bean @Primary MutableClock imageTestClock() { return new MutableClock(); }
    }
    @Autowired JdbcTemplate jdbc;
    @Autowired ObjectMapper json;
    @Autowired MockMvc mvc;
    @Autowired QuestionService questions;
    @Autowired BattleService battles;
    @Autowired BattleProcessor processor;
    @Autowired AuthProcessor auth;
    @Autowired RealtimeSessionService sessions;
    @Autowired SubscriptionService subscriptions;
    @Autowired MutableClock clock;
    @Autowired BattleSnapshotMapper snapshots;
    @LocalServerPort int port;

    JsonNode manifest() throws Exception {
        return json.readTree(getClass().getResourceAsStream("/question-images-manifest.json")).path("entries");
    }

    @Test void legacyFrozenJsonAndActualOvertimeProjectOnlyTheirOwnImage() throws Exception {
        var entries=manifest();String main=entries.get(0).path("imageKey").asText();String overtime=entries.get(1).path("imageKey").asText();
        var battle=waiting(1,BattleMode.PRIVATE,1000,1000);
        battle.getState().getRounds().getFirst().getQuestion().setImageKey(main);
        var extra=json.readValue(json.writeValueAsBytes(battle.getState().getRounds().getFirst().getQuestion()),FrozenQuestionDto.class);
        extra.setImageKey(overtime);battle.getState().setOvertimeQuestion(extra);battle.getState().setOvertimeSeconds(20);
        var engine=new BattleEngineImpl();engine.ready(battle,player(battle,0),START);engine.ready(battle,player(battle,1),START);engine.advance(battle,START.plusSeconds(3));
        assertThat(snapshots.toResponse(snapshots.snapshot(battle,player(battle,0),START.plusSeconds(3))).getRound().getQuestion().getImageUrl()).isEqualTo("/media/questions/"+main);
        engine.advance(battle,START.plusSeconds(18));
        var view=snapshots.toResponse(snapshots.snapshot(battle,player(battle,0),START.plusSeconds(18)));
        assertThat(view.getRound().isOvertimeRound()).isTrue();assertThat(view.getRound().getQuestion().getImageUrl()).isEqualTo("/media/questions/"+overtime);
        var legacy=(com.fasterxml.jackson.databind.node.ObjectNode)json.valueToTree(extra);legacy.remove("imageKey");
        var frozen=json.treeToValue(legacy,FrozenQuestionDto.class);assertThat(frozen.getImageKey()).isNull();
        assertThat(snapshots.toResponse(snapshots.question(frozen)).getImageUrl()).isNull();
    }

    @Test void allOriginalPngsAndReadyBindingsMatchExactly() throws Exception {
        var entries=manifest(); assertThat(entries).hasSize(23);
        int ready=0;
        for(var e:entries) {
            String key=e.path("imageKey").asText();
            byte[] bytes=getClass().getResourceAsStream("/question-images/"+key).readAllBytes();
            assertThat(bytes.length).isEqualTo(e.path("sizeBytes").asInt());
            assertThat(HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes))).isEqualTo(e.path("sha256").asText());
            var image=ImageIO.read(new ByteArrayInputStream(bytes)); assertThat(image).isNotNull();
            assertThat(image.getWidth()).isEqualTo(e.path("width").asInt());
            assertThat(image.getHeight()).isEqualTo(e.path("height").asInt());
            if(e.path("bindingStatus").asText().equals("READY")) {
                ready++;
                var row=jdbc.queryForMap("SELECT * FROM questions WHERE external_key=? AND active",e.path("externalKey").asText());
                assertThat(row.get("image_key")).isEqualTo(key);
                assertThat(row.get("content_version")).isEqualTo(2);
                assertThat(row.get("difficulty")).isEqualTo(e.path("difficulty").asText());
                assertThat(row.get("discipline_code")).isEqualTo(e.path("disciplineCode").asText());
                assertThat(jdbc.queryForObject("SELECT id FROM questions WHERE external_key=? AND content_version=1",UUID.class,e.path("externalKey").asText()).toString()).isEqualTo(e.path("seedQuestionId").asText());
            } else {
                assertThat(e.path("externalKey").asText()).isEqualTo("SAT_MATH:15ce8207");
                assertThat(jdbc.queryForObject("SELECT count(*) FROM questions WHERE external_key=?",Integer.class,e.path("externalKey").asText())).isZero();
            }
        }
        assertThat(ready).isEqualTo(22);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM questions",Integer.class)).isEqualTo(261);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM questions WHERE active",Integer.class)).isEqualTo(239);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM questions WHERE active AND image_key IS NULL",Integer.class)).isEqualTo(217);
    }

    @Test void v14UpgradePreservesAllContentCustomDataAndHistoryAndRefusesNewerSources() {
        var before=flyway("images_upgrade","12");before.migrate();
        // Explicit test fixtures replace the removed demonstration-account migration.
        jdbc.update("""
                INSERT INTO images_upgrade.users(id,created_at,updated_at,email_normalized,nickname,nickname_normalized,password_hash)
                VALUES ('00000000-0000-0000-0000-000000000001',now(),now(),'first@example.test','First','first','test-only hash'),
                       ('00000000-0000-0000-0000-000000000002',now(),now(),'second@example.test','Second','second','test-only hash')
                """);
        jdbc.update("""
                INSERT INTO images_upgrade.ratings(id,created_at,updated_at,user_id,discipline_code,rating,season_id)
                SELECT gen_random_uuid(),now(),now(),id,'SAT_MATH',1375,'FALL_2026' FROM images_upgrade.users
                """);
        jdbc.update("""
                INSERT INTO images_upgrade.battles(id,created_at,updated_at,first_user_id,second_user_id,
                    discipline_code,mode,phase,version,state,result)
                VALUES(gen_random_uuid(),now(),now(),
                    (SELECT id FROM images_upgrade.users ORDER BY id LIMIT 1),
                    (SELECT id FROM images_upgrade.users ORDER BY id LIMIT 1 OFFSET 1),
                    'SAT_MATH','PRIVATE','CANCELLED',1,
                    '{"rounds":[{"question":{"prompt":"Original legacy history"}}]}'::jsonb,
                    '{"reason":"SERVER_INTERRUPTION"}'::jsonb)
                """);
        var history=jdbc.queryForList("SELECT row_to_json(b)::text FROM images_upgrade.battles b ORDER BY id");
        var users=jdbc.queryForList("SELECT row_to_json(u)::text FROM images_upgrade.users u ORDER BY id");
        var ratings=jdbc.queryForList("SELECT row_to_json(r)::text FROM images_upgrade.ratings r ORDER BY id");
        var checksums=jdbc.queryForList("SELECT version,checksum FROM images_upgrade.flyway_schema_history ORDER BY installed_rank");
        var old=jdbc.queryForList("SELECT (to_jsonb(q)-'active'-'updated_at')::text AS value FROM images_upgrade.questions q ORDER BY id");
        jdbc.update("INSERT INTO images_upgrade.questions (id,created_at,updated_at,deleted,external_key,content_version,discipline_code,topic_code,topic_name,difficulty,prompt,options,correct_option_id,explanation,active) SELECT '00000000-0000-4000-8000-000000000099'::uuid,created_at,updated_at,deleted,'CUSTOM_KEEP',content_version,discipline_code,topic_code,topic_name,difficulty,prompt,options,correct_option_id,explanation,active FROM images_upgrade.questions LIMIT 1");
        var custom=jdbc.queryForList("SELECT to_jsonb(q)::text AS row_to_json FROM images_upgrade.questions q WHERE external_key='CUSTOM_KEEP'");
        var latest=flyway("images_upgrade","14");assertThat(latest.migrate().migrationsExecuted).isEqualTo(1);
        assertThat(jdbc.queryForList("SELECT (to_jsonb(q)-'active'-'updated_at'-'image_key')::text AS value FROM images_upgrade.questions q WHERE content_version=1 AND external_key<>'CUSTOM_KEEP' ORDER BY id")).isEqualTo(old);
        assertThat(jdbc.queryForList("SELECT (to_jsonb(q)-'image_key')::text AS row_to_json FROM images_upgrade.questions q WHERE external_key='CUSTOM_KEEP'")).isEqualTo(custom);
        assertThat(jdbc.queryForList("SELECT row_to_json(u)::text FROM images_upgrade.users u ORDER BY id")).isEqualTo(users);
        assertThat(jdbc.queryForList("SELECT row_to_json(r)::text FROM images_upgrade.ratings r ORDER BY id")).isEqualTo(ratings);
        assertThat(jdbc.queryForList("SELECT row_to_json(b)::text FROM images_upgrade.battles b ORDER BY id")).isEqualTo(history);
        assertThat(jdbc.queryForList("SELECT version,checksum FROM images_upgrade.flyway_schema_history WHERE version::int<=12 OR version IS NULL ORDER BY installed_rank")).isEqualTo(checksums);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM images_upgrade.questions a JOIN images_upgrade.questions b USING(external_key) WHERE a.content_version=1 AND b.content_version=2 AND (a.prompt,a.options,a.correct_option_id,a.explanation,a.topic_code,a.topic_name,a.difficulty) IS DISTINCT FROM (b.prompt,b.options,b.correct_option_id,b.explanation,b.topic_code,b.topic_name,b.difficulty)",Integer.class)).isZero();
        assertThat(latest.migrate().migrationsExecuted).isZero();latest.validate();
        flyway("images_conflict","12").migrate();
        jdbc.update("UPDATE images_conflict.questions SET content_version=3 WHERE external_key='SAT_MATH:3f5a3602'");
        var conflictBefore=jdbc.queryForList("SELECT row_to_json(q)::text FROM images_conflict.questions q ORDER BY id");
        assertThatThrownBy(()->flyway("images_conflict","14").migrate()).hasStackTraceContaining("conflicts with expected V12 revision 1");
        assertThat(jdbc.queryForList("SELECT row_to_json(q)::text FROM images_conflict.questions q ORDER BY id")).isEqualTo(conflictBefore);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM information_schema.columns WHERE table_schema='images_conflict' AND table_name='questions' AND column_name='image_key'",Integer.class)).isZero();
    }

    @Test @Transactional void legacyAndImageImportsAreIdempotentAndCannotChangeAnExistingRevision() throws Exception {
        var e=manifest().get(0);String external=e.path("externalKey").asText();
        var row=jdbc.queryForMap("SELECT * FROM questions WHERE external_key=? AND content_version=1",external);
        var legacy=importDto(row);assertThat(legacy.getImageKey()).isNull();
        assertThat(questions.importQuestions(List.of(legacy),false).getUnchanged()).isEqualTo(1);
        var illustrated=importDto(row);illustrated.setContentVersion(2);illustrated.setImageKey(e.path("imageKey").asText());
        assertThat(questions.importQuestions(List.of(illustrated),false).getUnchanged()).isEqualTo(1);
        illustrated.setImageKey(null);
        assertThatThrownBy(()->questions.importQuestions(List.of(illustrated),false)).isInstanceOf(ConflictException.class);
    }

    @Test @Transactional void importRejectsUrlsTraversalMissingAssetsAndWrongLogicalIdentity() throws Exception {
        var row=jdbc.queryForMap("SELECT * FROM questions WHERE external_key='SAT_MATH:3f5a3602' AND content_version=1");
        var dto=importDto(row);dto.setContentVersion(3);
        String key="SAT_MATH/3f5a3602/224eefc655e44ddac7e07d499e9fad2ba90e28bd8db675e8cd15b31156b7a203.png";
        for(String invalid:List.of("", "https://example.com/image.png", "/"+key, "../"+key,key+"?x=1",key.replace("3f5a3602","00000000"),key.replace("224eefc6","00000000"),key.replace("SAT_MATH","SAT_RW"))) {
            dto.setImageKey(invalid);
            assertThatThrownBy(()->questions.importQuestions(List.of(dto),true)).isInstanceOf(BusinessValidationException.class);
        }
        dto.setImageKey(key);assertThat(questions.importQuestions(List.of(dto),true).getInserted()).isEqualTo(1);
    }

    @Test void anonymousGetHeadConditionalAndNamespaceAreSafe() throws Exception {
        for(var e:manifest()) {
            String url=e.path("imageUrl").asText();
            var get=mvc.perform(get(url)).andReturn().getResponse();assertThat(get.getStatus()).isEqualTo(200);
            assertThat(get.getContentType()).isEqualTo("image/png");
            assertThat(get.getHeader("X-Content-Type-Options")).isEqualTo("nosniff");
            assertThat(get.getHeader("Cache-Control").split(",\\s*")).containsExactlyInAnyOrder("public","max-age=31536000","immutable");
            assertThat(HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(get.getContentAsByteArray()))).isEqualTo(e.path("sha256").asText());
            var head=mvc.perform(head(url)).andReturn().getResponse();assertThat(head.getStatus()).isEqualTo(200);
            assertThat(head.getContentAsByteArray()).isEmpty();assertThat(head.getHeader("Content-Length")).isEqualTo(Integer.toString(e.path("sizeBytes").asInt()));
            var conditional=mvc.perform(get(url).header("If-Modified-Since",get.getHeader("Last-Modified"))).andReturn().getResponse();
            assertThat(conditional.getStatus()).isEqualTo(304);assertThat(conditional.getContentAsByteArray()).isEmpty();
        }
        String missing="/media/questions/SAT_MATH/00000000/"+"0".repeat(64)+".png";
        var absent=mvc.perform(get(missing)).andReturn().getResponse();assertThat(absent.getStatus()).isEqualTo(404);
        assertThat(json.readTree(absent.getContentAsString()).path("code").asText()).isEqualTo("NOT_FOUND");
        assertThat(absent.getHeader("Cache-Control")).doesNotContain("immutable");
        assertThat(mvc.perform(head(missing)).andReturn().getResponse().getContentAsByteArray()).isEmpty();
        for(String path:List.of("/media/questions/","/media/questions/application.yml","/media/questions/../application.yml","/media/questions/%2e%2e/application.yml","/media/questions/SAT_MATH/3f5a3602/"))
            assertThat(mvc.perform(get(path)).andReturn().getResponse().getStatus()).isIn(400,404);
        assertThat(mvc.perform(post(missing)).andReturn().getResponse().getStatus()).isEqualTo(401);
        assertThat(mvc.perform(get("/api/v1/users/me")).andReturn().getResponse().getStatus()).isEqualTo(401);
    }

    @Test void actualStompAndRestUseFrozenMainAndOvertimeImagesWithoutAnswerLeaks() throws Exception {
        clock.set(START);
        var a=register();var b=register();var c=register();
        try(var http=HttpClient.newHttpClient();var sa=connect(http,a);var sb=connect(http,b);var sc=connect(http,c)) {
            // Restrict only this isolated test's bank to image-bearing revisions for deterministic coverage.
            jdbc.update("UPDATE questions SET active=false WHERE image_key IS NULL");
            UUID id=processor.create(new CreateBattleDto(a.getUser().getId(),b.getUser().getId(),"SAT_MATH",BattleMode.PRIVATE));
            assertThat(processor.snapshot(id,a.getUser().getId()).getRound()).isNull();
            var frozen=battles.getForParticipant(id,a.getUser().getId());
            assertThat(frozen.getState().getRounds()).allSatisfy(r->assertThat(r.getQuestion().getImageKey()).isNotNull());
            assertThat(frozen.getState().getOvertimeQuestion().getImageKey()).isNotNull();
            processor.ready(id,a.getUser().getId());processor.ready(id,b.getUser().getId());
            clock.set(START.plusSeconds(3));processor.tick(id);
            var event=sa.event(e->e.path("data").path("phase").asText().equals("QUESTION"));
            var rest=rest(http,"/api/v1/battles/"+id,a,200);
            var question=rest.path("round").path("question");
            assertThat(event.path("data").path("round").path("question")).isEqualTo(question);
            assertThat(question.path("imageUrl").asText()).isEqualTo("/media/questions/"+frozen.getState().getRounds().getFirst().getQuestion().getImageKey());
            assertThat(question.has("imageKey")).isFalse();assertThat(question.has("correctOptionId")).isFalse();assertThat(question.has("explanation")).isFalse();
            assertThat(sc.hasMessage(Duration.ofMillis(200))).isFalse();
            rest(http,"/api/v1/battles/"+id,c,404);
            // New current revision must not replace an already frozen URL.
            var source=jdbc.queryForMap("SELECT * FROM questions WHERE id=?",frozen.getState().getRounds().getFirst().getQuestion().getId());
            var changed=importDto(source);changed.setContentVersion(3);changed.setImageKey(null);questions.importQuestions(List.of(changed),false);
            assertThat(rest(http,"/api/v1/battles/"+id,a,200).path("round").path("question")).isEqualTo(question);
            processor.surrender(id,a.getUser().getId());
            var review=rest(http,"/api/v1/battles/"+id+"/review",a,200).path("rounds").get(0).path("question");
            assertThat(review.path("imageUrl")).isEqualTo(question.path("imageUrl"));
            assertThat(review.path("correctOptionId").isTextual()).isTrue();assertThat(review.path("explanation").asText()).isNotBlank();
            // Legacy persisted JSON, including overtime, is readable without looking up today's bank.
            jdbc.update("UPDATE battles SET state=jsonb_set(state,'{rounds,0,question}',(state#>'{rounds,0,question}')-'imageKey') WHERE id=?",id);
            assertThat(rest(http,"/api/v1/battles/"+id,a,200).path("round").path("question").path("imageUrl").isNull()).isTrue();
        } finally {
            jdbc.update("DELETE FROM questions WHERE content_version>2");
            jdbc.update("UPDATE questions q SET active=(content_version=(SELECT max(content_version) FROM questions r WHERE r.external_key=q.external_key))");
        }
    }

    private QuestionImportDto importDto(Map<String,Object> row) throws Exception {
        var dto=new QuestionImportDto();dto.setExternalKey(row.get("external_key").toString());dto.setContentVersion((Integer)row.get("content_version"));
        dto.setDisciplineCode(row.get("discipline_code").toString());dto.setTopicCode(row.get("topic_code").toString());dto.setTopicName(row.get("topic_name").toString());
        dto.setDifficulty(Difficulty.valueOf(row.get("difficulty").toString()));dto.setPrompt(row.get("prompt").toString());dto.setExplanation(row.get("explanation").toString());
        List<QuestionOptionImportDto> options=new ArrayList<>();
        for(var item:json.readTree(row.get("options").toString())) {var o=new QuestionOptionImportDto();o.setKey(item.path("key").asText());o.setText(item.path("text").asText());options.add(o);if(item.path("id").asText().equals(row.get("correct_option_id").toString()))dto.setCorrectOptionKey(o.getKey());}
        dto.setOptions(options);dto.setImageKey((String)row.get("image_key"));return dto;
    }
    private Flyway flyway(String schema,String target) { return Flyway.configure().dataSource(POSTGRES.getJdbcUrl(),POSTGRES.getUsername(),POSTGRES.getPassword()).schemas(schema).target(target).load(); }
    private AuthDto register() {var r=new RegisterDto();r.setBirthYear(2000);r.setBirthMonth(1);String n=UUID.randomUUID().toString().replace("-","").substring(0,12);r.setEmail(n+"@example.com");r.setNickname("Image_"+n);r.setPassword("ExamplePass123!");return auth.register(r);}
    private NativeStompClient connect(HttpClient http,AuthDto a)throws Exception {var c=new NativeStompClient(http,URI.create("ws://localhost:"+port+"/ws/v1/events"),"http://localhost:"+port,json);c.connect(a.getTokens().getAccessToken());c.await("CONNECTED");c.startHeartbeats();c.subscribe("/user/queue/events");await().atMost(Duration.ofSeconds(5)).until(()->sessions.current(a.getUser().getId()).isPresent());return c;}
    private JsonNode rest(HttpClient http,String path,AuthDto a,int status)throws Exception {var r=http.send(HttpRequest.newBuilder(URI.create("http://localhost:"+port+path)).header("Authorization","Bearer "+a.getTokens().getAccessToken()).GET().build(),HttpResponse.BodyHandlers.ofString());assertThat(r.statusCode()).isEqualTo(status);return json.readTree(r.body());}
}
