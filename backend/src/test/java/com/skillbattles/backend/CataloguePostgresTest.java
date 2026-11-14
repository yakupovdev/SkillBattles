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
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.*;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.flywaydb.core.Flyway;
import org.springframework.test.web.servlet.MockMvc;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.*;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.*;
import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.mockito.Mockito.*;

@SpringBootTest(properties = {"app.jwt.secret=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=", "app.battle.scheduling.enabled=false", "app.matchmaking.scheduling.enabled=false"})
@AutoConfigureMockMvc @Testcontainers(disabledWithoutDocker = true) @DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
class CataloguePostgresTest {
    @Container static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:17.12-alpine");
    @DynamicPropertySource static void database(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl); registry.add("spring.datasource.username", POSTGRES::getUsername); registry.add("spring.datasource.password", POSTGRES::getPassword);
    }
    @Autowired AuthProcessor auth;
    @Autowired QuestionImportProcessor imports;
    @Autowired QuestionImportFileService files;
    @MockitoSpyBean DisciplineService disciplines;
    @Autowired RatingService ratings;
    @Autowired QuestionService questions;
    @Autowired PlatformTransactionManager transactions;
    @Autowired BattleModeProcessor modes;
    @Autowired BattleProcessor processor;
    @Autowired BattleService battles;
    @Autowired JdbcTemplate jdbc;
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;

    @BeforeEach void setup() { jdbc.execute("TRUNCATE ranked_usage, battles, questions"); jdbc.execute("UPDATE disciplines SET active=false WHERE code NOT IN ('SAT_MATH','SAT_RW')"); }
    @AfterEach void cleanup() { jdbc.execute("UPDATE disciplines SET active=false WHERE code NOT IN ('SAT_MATH','SAT_RW')"); }

    @Test void cataloguesExposeExactTimingsSchedulesAndAllTwentySevenRanksWithoutContent() throws Exception {
        var user = register();
        var catalogue = catalogue(user);
        assertThat(catalogue.size()).isEqualTo(2);
        var math = catalogue.get(0); var rw = catalogue.get(1);
        assertThat(math.path("disciplineCode").asText()).isEqualTo("SAT_MATH"); assertThat(rw.path("disciplineCode").asText()).isEqualTo("SAT_RW");
        assertThat(math.path("format").asText()).isEqualTo("STANDARD"); assertThat(math.path("questionType").asText()).isEqualTo("SINGLE_CHOICE");
        assertThat(math.path("optionsCount").asInt()).isEqualTo(4); assertThat(math.path("questionCount").asInt()).isEqualTo(5);
        assertThat(math.path("difficultyTimings").findValues("limitSeconds")).extracting(JsonNode::asInt).containsExactly(45,60,90);
        assertThat(rw.path("difficultyTimings").findValues("limitSeconds")).extracting(JsonNode::asInt).containsExactly(36,48,72);
        assertThat(math.path("difficultyTimings").findValues("basePoints")).extracting(JsonNode::asInt).containsExactly(800,1000,1200);
        assertThat(math.path("overtimeSeconds").asInt()).isEqualTo(30); assertThat(rw.path("overtimeSeconds").asInt()).isEqualTo(24);
        assertThat(math.path("difficultySchedules").size()).isEqualTo(4);
        assertThat(math.path("difficultySchedules").get(3).path("maxRatingExclusive").isNull()).isTrue();
        assertThat(math.path("difficultySchedules").get(0).path("roundDifficulties").toString()).isEqualTo("[\"EASY\",\"EASY\",\"EASY\",\"MEDIUM\",\"MEDIUM\"]");
        assertThat(math.path("contentAvailable").asBoolean()).isFalse();
        var ranks = getJson("/api/v1/ranks", user);
        assertThat(ranks).isEqualTo(json.valueToTree(RankFixtures.tiers()));
        assertThat(ranks.get(26).path("ceilingExclusive").isNull()).isTrue();
        for (String path : List.of("/api/v1/ranks", "/api/v1/battle-modes")) {
            mvc.perform(get(path)).andExpect(status().isUnauthorized()).andExpect(jsonPath("$.resetsAt").isEmpty());
            mvc.perform(get(path).header("Authorization", "Bearer " + user.getTokens().getRefreshToken())).andExpect(status().isUnauthorized());
        }
    }

    @Test void availabilityRequiresSixUniqueQuestionsAndMediumReserveForEveryGrid() throws Exception {
        var user = register(); var original = disciplines.get("SAT_MATH").getTopics();
        imports.importQuestions(fixture(), true);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM questions", Integer.class)).isZero();
        assertThat(disciplines.get("SAT_MATH").getTopics()).isEqualTo(original);
        imports.importQuestions(fixture(), false);
        assertThat(catalogue(user).get(0).path("contentAvailable").asBoolean()).isTrue();
        for (var schedule : catalogue(user).get(0).path("difficultySchedules")) assertThat(schedule.path("contentAvailable").asBoolean()).isTrue();
        jdbc.update("UPDATE questions SET active=false WHERE external_key='test-math-1'");
        var depleted = catalogue(user).get(0);
        for (var schedule : depleted.path("difficultySchedules")) assertThat(schedule.path("contentAvailable").asBoolean()).isFalse();
        assertThat(depleted.path("contentAvailable").asBoolean()).isFalse();
    }

    @Test void pairGridUsesLowerRatingAndActualCreationRejectsMissingDifficultyWithoutOrphans() throws Exception {
        imports.importQuestions(fixture(), false); var a=register(); var b=register();
        jdbc.update("UPDATE questions SET active=false WHERE discipline_code='SAT_MATH' AND difficulty='HARD'");
        assertThatThrownBy(() -> processor.create(new CreateBattleDto(id(a),id(b),"SAT_MATH",BattleMode.PRIVATE)))
                .isInstanceOfSatisfying(com.skillbattles.backend.exception.ConflictException.class, ex -> assertThat(ex.getCode()).isEqualTo("CONTENT_UNAVAILABLE"));
        assertThat(jdbc.queryForObject("SELECT count(*) FROM battles",Integer.class)).isZero();
        jdbc.update("UPDATE ratings SET rating=999 WHERE user_id=? AND discipline_code='SAT_MATH'",id(a));
        UUID battleId=processor.create(new CreateBattleDto(id(a),id(b),"SAT_MATH",BattleMode.PRIVATE));
        var state=battles.lock(battleId).getState();
        assertThat(state.getRounds()).extracting(round -> round.getQuestion().getDifficulty()).containsExactly(Difficulty.EASY,Difficulty.EASY,Difficulty.EASY,Difficulty.MEDIUM,Difficulty.MEDIUM);
        assertThat(state.getOvertimeQuestion().getDifficulty()).isEqualTo(Difficulty.MEDIUM);
        var unique=new HashSet<>(state.getRounds().stream().map(round -> round.getQuestion().getId()).toList());
        unique.add(state.getOvertimeQuestion().getId()); assertThat(unique).hasSize(6);
        assertThat(state.getRounds()).extracting(BattleRoundDto::getLimitSeconds).containsExactly(45,45,45,60,60);
    }

    @ParameterizedTest @CsvSource({"0,EEEMM,RANKED", "999,EEEMM,PRIVATE", "1000,EEMMH,RANKED", "1899,EEMMH,PRIVATE", "1900,EMMHH,RANKED", "2799,EMMHH,PRIVATE", "2800,MMHHH,RANKED", "4000,MMHHH,PRIVATE"})
    void everyPairRatingBoundaryUsesItsConfiguredOrderedGrid(int lower, String grid, BattleMode mode) throws Exception {
        imports.importQuestions(fixture(),false); var a=register(); var b=register();
        jdbc.update("UPDATE ratings SET rating=? WHERE user_id=? AND discipline_code='SAT_MATH'",lower,id(a));
        jdbc.update("UPDATE ratings SET rating=? WHERE user_id=? AND discipline_code='SAT_MATH'",lower+50,id(b));
        var state=battles.lock(processor.create(new CreateBattleDto(id(a),id(b),"SAT_MATH",mode))).getState();
        var expected=grid.chars().mapToObj(c -> c=='E'?Difficulty.EASY:c=='M'?Difficulty.MEDIUM:Difficulty.HARD).toList();
        assertThat(state.getRounds()).extracting(round -> round.getQuestion().getDifficulty()).containsExactlyElementsOf(expected);
        assertThat(state.getRounds()).extracting(BattleRoundDto::getLimitSeconds).containsExactlyElementsOf(expected.stream().map(d -> d==Difficulty.EASY?45:d==Difficulty.MEDIUM?60:90).toList());
        var ids=new HashSet<>(state.getRounds().stream().map(r -> r.getQuestion().getId()).toList());
        assertThat(ids.add(state.getOvertimeQuestion().getId())).isTrue(); assertThat(ids).hasSize(6);
    }

    @Test void additionalDisciplineNeedsOnlyDataAndInitializesExistingAndNewAccountsIdempotently() throws Exception {
        var existing=register(); String code=customDiscipline();
        List<QuestionImportDto> batch=fixture().stream().filter(q -> q.getDisciplineCode().equals("SAT_MATH")).toList();
        batch.forEach(q -> {q.setDisciplineCode(code);q.setExternalKey("custom-"+q.getExternalKey());q.setTopicCode("CUSTOM_TOPIC");q.setTopicName("Custom topic");});
        imports.importQuestions(batch,false); // Loading a defined inactive discipline is allowed before activation.
        assertThatThrownBy(() -> processor.create(new CreateBattleDto(id(existing),id(register()),code,BattleMode.PRIVATE)))
                .isInstanceOfSatisfying(com.skillbattles.backend.exception.ConflictException.class,ex -> assertThat(ex.getCode()).isEqualTo("DISCIPLINE_UNAVAILABLE"));
        jdbc.update("UPDATE disciplines SET active=true WHERE code=?",code);
        jdbc.update("UPDATE ratings SET rating=1678 WHERE user_id=? AND discipline_code='SAT_MATH'",id(existing));
        modes.initializeActiveRatings(); modes.initializeActiveRatings();
        assertThat(ratings.getByUserId(id(existing))).hasSize(3);
        assertThat(ratings.getByUserId(id(existing)).stream().filter(r -> r.getDisciplineCode().equals(code)).findFirst().orElseThrow().getRating()).isEqualTo(1000);
        assertThat(ratings.getByUserId(id(existing)).stream().filter(r -> r.getDisciplineCode().equals("SAT_MATH")).findFirst().orElseThrow().getRating()).isEqualTo(1678);
        var newcomer=register(); assertThat(ratings.getByUserId(id(newcomer))).hasSize(3);
        assertThat(catalogue(existing).findValuesAsText("disciplineCode")).contains(code);
        UUID battleId=processor.create(new CreateBattleDto(id(existing),id(newcomer),code,BattleMode.PRIVATE));
        var before=battles.lock(battleId).getState();
        assertThat(before.getRounds().getFirst().getQuestion().getTopicCode()).isEqualTo("CUSTOM_TOPIC");
        assertThat(before.getRounds().getFirst().getQuestion().getOptions()).hasSize(4);
        assertThat(before.getRounds()).extracting(BattleRoundDto::getLimitSeconds).containsExactly(36,36,48,48,72);
        jdbc.update("UPDATE disciplines SET base_question_seconds=120 WHERE code=?",code);
        assertThat(battles.lock(battleId).getState()).isEqualTo(before);
        assertThat(disciplines.get(code).getTopics()).containsExactly(new TopicDto("CUSTOM_TOPIC","Custom topic"));
    }

    @Test void invalidBatchAndRevisionConflictCannotPartiallyChangeTopicsOrQuestions() throws Exception {
        var batch=fixture(); batch.get(1).setTopicName("Conflicting topic name");
        assertThatThrownBy(() -> imports.importQuestions(batch,false)).isInstanceOf(com.skillbattles.backend.exception.BusinessValidationException.class);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM questions",Integer.class)).isZero();
        var unknown=fixture().getFirst();unknown.setDisciplineCode("UNKNOWN_CODE");
        assertThatThrownBy(() -> imports.importQuestions(List.of(unknown),false)).isInstanceOf(com.skillbattles.backend.exception.BusinessValidationException.class);
        imports.importQuestions(fixture(),false);
        var before=disciplines.get("SAT_MATH").getTopics();
        var conflicting=fixture().getFirst();conflicting.setTopicCode("NEW_TOPIC");conflicting.setTopicName("New topic");
        assertThatThrownBy(() -> imports.importQuestions(List.of(conflicting),false)).isInstanceOf(com.skillbattles.backend.exception.ConflictException.class);
        assertThat(disciplines.get("SAT_MATH").getTopics()).isEqualTo(before);
    }

    @Test void failureAfterQuestionFlushAndTopicUpdateRollsBackBothAggregates() throws Exception {
        var before=disciplines.get("SAT_MATH").getTopics();
        var batch=fixture(); batch.forEach(q -> {q.setTopicCode("ROLLBACK_TOPIC");q.setTopicName("Rollback topic");});
        doAnswer(call -> {call.callRealMethod();throw new IllegalStateException("Test-only failure after topic merge");}).when(disciplines).mergeTopics(eq("SAT_MATH"),anyList());
        assertThatThrownBy(() -> imports.importQuestions(batch,false)).isInstanceOf(IllegalStateException.class);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM questions",Integer.class)).isZero();
        assertThat(disciplines.get("SAT_MATH").getTopics()).isEqualTo(before);
    }

    @Test void importCannotMoveARevisionBetweenDifficultyBucketsDuringBattleSelection() throws Exception {
        imports.importQuestions(fixture(),false);
        var revision=fixture().stream().filter(q -> q.getDisciplineCode().equals("SAT_MATH") && q.getDifficulty()==Difficulty.EASY).findFirst().orElseThrow();
        revision.setContentVersion(2); revision.setDifficulty(Difficulty.MEDIUM);
        List<Future<?>> pending=new ArrayList<>();
        try (var executor=Executors.newFixedThreadPool(2)) {
            new TransactionTemplate(transactions).executeWithoutResult(tx -> {
                var easy=questions.selectForBattle(new QuestionSelectionDto("SAT_MATH",3,List.of(),Difficulty.EASY));
                pending.add(executor.submit(() -> imports.importQuestions(List.of(revision),false)));
                var waiting=executor.submit(() -> {
                    for (int attempt=0;attempt<500;attempt++) {
                        if (jdbc.queryForObject("SELECT count(*) FROM pg_stat_activity WHERE datname=current_database() AND wait_event_type='Lock' AND wait_event='advisory'",Integer.class)>0) return true;
                        Thread.sleep(10);
                    }
                    return false;
                });
                try { assertThat(waiting.get(10,TimeUnit.SECONDS)).isTrue(); }
                catch (Exception ex) { throw new AssertionError("Import did not wait for the selection transaction",ex); }
                assertThat(pending.getFirst().isDone()).isFalse();
                var medium=questions.selectForBattle(new QuestionSelectionDto("SAT_MATH",3,List.of(),Difficulty.MEDIUM));
                var ids=new ArrayList<>(easy.stream().map(FrozenQuestionDto::getId).toList());
                ids.addAll(medium.stream().map(FrozenQuestionDto::getId).toList());
                String keys=String.join(",",Collections.nCopies(ids.size(),"?"));
                assertThat(jdbc.queryForObject("SELECT count(DISTINCT external_key) FROM questions WHERE id IN ("+keys+")",Integer.class,ids.toArray())).isEqualTo(6);
            });
            pending.getFirst().get(10,TimeUnit.SECONDS);
        }
        assertThat(jdbc.queryForObject("SELECT content_version FROM questions WHERE external_key=? AND active",Integer.class,revision.getExternalKey())).isEqualTo(2);
        assertThat(jdbc.queryForObject("SELECT difficulty FROM questions WHERE external_key=? AND active",String.class,revision.getExternalKey())).isEqualTo("MEDIUM");
    }

    @Test void migrationRefusesPopulatedLegacyBankAndKeepsItsRowsIntact() {
        Flyway.configure().dataSource(POSTGRES.getJdbcUrl(),POSTGRES.getUsername(),POSTGRES.getPassword()).schemas("legacy_guard").target("4").load().migrate();
        jdbc.update("""
            INSERT INTO legacy_guard.questions (id,created_at,updated_at,deleted,external_key,content_version,subject,topic,difficulty,prompt,options,correct_option_id,explanation,active)
            VALUES (gen_random_uuid(),now(),now(),false,'test-only-legacy',1,'MATH','Test only','MEDIUM','TEST ONLY','[{},{},{},{}]'::jsonb,gen_random_uuid(),'TEST ONLY',true)
            """);
        assertThatThrownBy(() -> Flyway.configure().dataSource(POSTGRES.getJdbcUrl(),POSTGRES.getUsername(),POSTGRES.getPassword()).schemas("legacy_guard").load().migrate())
                .hasStackTraceContaining("requires a separate database without v0.2 questions or battles");
        assertThat(jdbc.queryForObject("SELECT count(*) FROM legacy_guard.questions",Integer.class)).isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT subject FROM legacy_guard.questions",String.class)).isEqualTo("MATH");
    }

    @Test void publicRequestsRequireExplicitFormatAndRejectOldSubjectsAndUnsupportedRenderer() throws Exception {
        var user=register();imports.importQuestions(fixture(),false);
        for (String body : List.of("{\"subject\":\"MATH\"}","{\"disciplineCode\":\"SAT_MATH\"}","{\"disciplineCode\":\"SAT_MATH\",\"format\":\"TURBO\"}"))
            mvc.perform(post("/api/v1/matchmaking/entries").header("Authorization",bearer(user)).contentType("application/json").content(body)).andExpect(status().isBadRequest());
        mvc.perform(post("/api/v1/matchmaking/entries").header("Authorization",bearer(user)).contentType("application/json").content("{\"disciplineCode\":\"MATH\",\"format\":\"STANDARD\"}"))
                .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("DISCIPLINE_UNAVAILABLE"));
        mvc.perform(post("/api/v1/matchmaking/entries").header("Authorization",bearer(user)).contentType("application/json").content("{\"disciplineCode\":\"SAT_MATH\",\"format\":\"STANDARD\"}"))
                .andExpect(status().isCreated()).andExpect(jsonPath("$.format").value("STANDARD")).andExpect(jsonPath("$.disciplineCode").value("SAT_MATH"));
    }

    private String customDiscipline() {
        String code="SAT_TEST_"+UUID.randomUUID().toString().replace("-","").substring(0,8).toUpperCase(Locale.ROOT);
        jdbc.update("""
            INSERT INTO disciplines (id,created_at,updated_at,deleted,code,display_name,description,active,format,question_type,options_count,question_count,base_question_seconds,overtime_seconds,display_order,timings,schedules,topics)
            SELECT gen_random_uuid(),created_at,updated_at,false,?,'Custom discipline','Test only',false,format,question_type,options_count,question_count,base_question_seconds,overtime_seconds,100,timings,schedules,'[]'::jsonb
            FROM disciplines WHERE code='SAT_RW'
            """,code);return code;
    }
    private JsonNode catalogue(AuthDto user)throws Exception{return getJson("/api/v1/battle-modes",user);}
    private JsonNode getJson(String path,AuthDto user)throws Exception{return json.readTree(mvc.perform(get(path).header("Authorization",bearer(user))).andExpect(status().isOk()).andReturn().getResponse().getContentAsString());}
    private String bearer(AuthDto user){return "Bearer "+user.getTokens().getAccessToken();}
    private UUID id(AuthDto user){return user.getUser().getId();}
    private List<QuestionImportDto> fixture()throws Exception{return files.read(Path.of(Objects.requireNonNull(getClass().getResource("/fixtures/stage2-questions-test-only.json")).toURI()));}
    private AuthDto register(){var dto=new RegisterDto();String suffix=UUID.randomUUID().toString().replace("-","").substring(0,12);dto.setEmail(suffix+"@example.com");dto.setNickname("Catalog_"+suffix);dto.setPassword("ExamplePass123!");return auth.register(dto);}
}
