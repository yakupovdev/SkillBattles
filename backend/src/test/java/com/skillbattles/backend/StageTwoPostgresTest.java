package com.skillbattles.backend;

import com.fasterxml.jackson.databind.*;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.exception.*;
import com.skillbattles.backend.processor.AuthProcessor;
import com.skillbattles.backend.repository.*;
import com.skillbattles.backend.service.*;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.*;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.test.web.servlet.MockMvc;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.*;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.*;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = "app.jwt.secret=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=")
@AutoConfigureMockMvc
@Testcontainers(disabledWithoutDocker = true)
class StageTwoPostgresTest {
    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:17.12-alpine");

    @DynamicPropertySource
    static void database(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
    }

    @Autowired MockMvc mvc;
    @Autowired JdbcTemplate jdbc;
    @Autowired ObjectMapper json;
    @Autowired QuestionService questions;
    @Autowired QuestionImportFileService files;
    @MockitoSpyBean RatingService ratings;
    @Autowired RatingRepository ratingRepository;
    @Autowired QuestionRepository questionRepository;
    @Autowired AuthProcessor auth;

    @BeforeEach
    void clearQuestions() { jdbc.execute("TRUNCATE TABLE questions"); }

    @Test
    void registrationCreatesIndependentRatingsAndStatisticsRequireAccess() throws Exception {
        AuthDto session = register();
        UUID id = session.getUser().getId();
        assertThat(ratings.getByUserId(id)).extracting(RatingDto::getRating).containsExactly(1000, 1000);
        String access = session.getTokens().getAccessToken();
        mvc.perform(get("/api/v1/users/me/statistics").header("Authorization", "Bearer " + access))
                .andExpect(status().isOk()).andExpect(jsonPath("$.subjects.length()").value(2))
                .andExpect(jsonPath("$.subjects[0].subject").value("MATH"))
                .andExpect(jsonPath("$.subjects[0].rating").value(1000))
                .andExpect(jsonPath("$.subjects[0].rank").value("Rookie"))
                .andExpect(jsonPath("$.subjects[0].ranked.played").value(0))
                .andExpect(jsonPath("$.subjects[1].subject").value("ENGLISH"))
                .andExpect(jsonPath("$.subjects[1].privateMatches.wins").value(0));
        jdbc.update("update ratings set rating = 1800 where user_id = ? and subject = 'ENGLISH'", id);
        mvc.perform(get("/api/v1/users/me/statistics").header("Authorization", "Bearer " + access))
                .andExpect(status().isOk()).andExpect(jsonPath("$.subjects[0].rating").value(1000))
                .andExpect(jsonPath("$.subjects[1].rating").value(1800)).andExpect(jsonPath("$.subjects[1].rank").value("Master"));
        for (String path : List.of("/api/v1/users/me/statistics", "/api/v1/battle-modes")) {
            mvc.perform(get(path)).andExpect(status().isUnauthorized()).andExpect(jsonPath("$.code").value("UNAUTHORIZED"));
            mvc.perform(get(path).header("Authorization", "Bearer " + session.getTokens().getRefreshToken())).andExpect(status().isUnauthorized());
        }
        auth.deleteUser(id);
        mvc.perform(get("/api/v1/users/me/statistics").header("Authorization", "Bearer " + access)).andExpect(status().isNotFound());
    }

    @Test
    void dryRunIdempotenceStableOptionsAndAvailability() throws Exception {
        String access = register().getTokens().getAccessToken();
        mvc.perform(get("/api/v1/battle-modes").header("Authorization", "Bearer " + access))
                .andExpect(status().isOk()).andExpect(jsonPath("$[0].questionCount").value(3))
                .andExpect(jsonPath("$[0].questionLimitSeconds").value(95)).andExpect(jsonPath("$[0].contentAvailable").value(false))
                .andExpect(jsonPath("$[1].questionCount").value(4)).andExpect(jsonPath("$[1].contentAvailable").value(false));
        List<QuestionImportDto> fixture = fixture();
        assertThat(questions.importQuestions(fixture, true).getInserted()).isEqualTo(7);
        assertThat(questionRepository.count()).isZero();
        assertThat(questions.importQuestions(fixture, false).getInserted()).isEqualTo(7);
        assertThat(Math.abs(jdbc.queryForObject("select extract(epoch from ((now() at time zone 'UTC') - created_at)) from questions limit 1", Double.class))).isLessThan(30);
        var before = jdbc.queryForList("select id, options::text, correct_option_id, updated_at from questions order by external_key");
        assertThat(questions.importQuestions(fixture, true).getUnchanged()).isEqualTo(7);
        assertThat(questions.importQuestions(fixture, false).getUnchanged()).isEqualTo(7);
        assertThat(jdbc.queryForList("select id, options::text, correct_option_id, updated_at from questions order by external_key")).isEqualTo(before);
        JsonNode options = json.readTree((String) before.getFirst().get("options"));
        assertThat(options.size()).isEqualTo(4);
        Set<String> ids = new HashSet<>();
        options.forEach(option -> ids.add(option.path("id").asText()));
        assertThat(ids).hasSize(4).contains(before.getFirst().get("correct_option_id").toString());
        mvc.perform(get("/api/v1/battle-modes").header("Authorization", "Bearer " + access))
                .andExpect(status().isOk()).andExpect(jsonPath("$[0].contentAvailable").value(true))
                .andExpect(jsonPath("$[1].contentAvailable").value(true)).andExpect(jsonPath("$[0].prompt").doesNotExist());
        jdbc.update("update questions set active = false where external_key = 'test-math-1'");
        mvc.perform(get("/api/v1/battle-modes").header("Authorization", "Bearer " + access))
                .andExpect(status().isOk()).andExpect(jsonPath("$[0].contentAvailable").value(false))
                .andExpect(jsonPath("$[1].contentAvailable").value(true));
        questions.importQuestions(fixture, false);
        assertThat(questions.countAvailable(Subject.MATH, Difficulty.MEDIUM)).isEqualTo(2);
    }

    @Test
    void newRevisionPreservesOldContentAndNeverDoubleCountsOrDowngrades() throws Exception {
        QuestionImportDto first = fixture().getFirst();
        first.setContentVersion(2);
        questions.importQuestions(List.of(first), false);
        String frozenOptions = jdbc.queryForObject("select options::text from questions", String.class);
        QuestionImportDto next = fixture().getFirst();
        next.setContentVersion(3);
        next.setPrompt("TEST ONLY: revised prompt");
        questions.importQuestions(List.of(next), false);
        assertThat(questionRepository.count()).isEqualTo(2);
        assertThat(questions.countAvailable(Subject.MATH, Difficulty.MEDIUM)).isEqualTo(1);
        assertThat(jdbc.queryForObject("select options::text from questions where content_version = 2", String.class)).isEqualTo(frozenOptions);
        questions.importQuestions(List.of(fixture().getFirst()), false);
        assertThat(questionRepository.count()).isEqualTo(3);
        assertThat(jdbc.queryForObject("select content_version from questions where active = true", Integer.class)).isEqualTo(3);
    }

    @Test
    void invalidBatchAndConflictingRevisionDoNotPartiallyImport() throws Exception {
        List<QuestionImportDto> fixture = fixture();
        fixture.getLast().getOptions().getLast().setKey("A");
        assertThatThrownBy(() -> questions.importQuestions(fixture, false)).isInstanceOf(BusinessValidationException.class);
        assertThat(questionRepository.count()).isZero();
        List<QuestionImportDto> valid = fixture();
        assertThatThrownBy(() -> questions.importQuestions(List.of(valid.getFirst(), valid.getFirst()), false)).isInstanceOf(BusinessValidationException.class);
        valid.getFirst().setCorrectOptionKey("Z");
        assertThatThrownBy(() -> questions.importQuestions(valid, false)).isInstanceOf(BusinessValidationException.class);
        questions.importQuestions(fixture(), false);
        List<QuestionImportDto> conflicting = fixture();
        conflicting.getFirst().setExternalKey("new-question");
        conflicting.getLast().setPrompt("TEST ONLY: changed without version bump");
        assertThatThrownBy(() -> questions.importQuestions(conflicting, false)).isInstanceOf(ConflictException.class);
        assertThat(questionRepository.count()).isEqualTo(7);
        assertThat(jdbc.queryForObject("select count(*) from questions where active = true", Integer.class)).isEqualTo(7);
    }

    @Test
    void concurrentImportsAreSerializedAndHighestRevisionRemainsActive() throws Exception {
        QuestionImportDto v2 = fixture().getFirst();
        v2.setContentVersion(2);
        QuestionImportDto v3 = fixture().getFirst();
        v3.setContentVersion(3);
        CountDownLatch ready = new CountDownLatch(2);
        CountDownLatch start = new CountDownLatch(1);
        try (ExecutorService executor = Executors.newFixedThreadPool(2)) {
            var first = executor.submit(() -> concurrentImport(v2, ready, start));
            var second = executor.submit(() -> concurrentImport(v3, ready, start));
            assertThat(ready.await(10, TimeUnit.SECONDS)).isTrue();
            start.countDown();
            assertThat(first.get(20, TimeUnit.SECONDS).getInserted()).isEqualTo(1);
            assertThat(second.get(20, TimeUnit.SECONDS).getInserted()).isEqualTo(1);
        }
        assertThat(questionRepository.count()).isEqualTo(2);
        assertThat(jdbc.queryForObject("select content_version from questions where active = true", Integer.class)).isEqualTo(3);
    }

    @Test
    void databaseEnforcesActiveUniquenessAndSoftDeleteAllowsReuse() throws Exception {
        UUID userId = register().getUser().getId();
        UUID old = jdbc.queryForObject("select id from ratings where user_id = ? and subject = 'MATH'", UUID.class, userId);
        String insert = "insert into ratings(id,created_at,updated_at,deleted,user_id,subject,rating) values (?,now(),now(),false,?,'MATH',1000)";
        assertThatThrownBy(() -> jdbc.update(insert, UUID.randomUUID(), userId)).isInstanceOf(DataIntegrityViolationException.class);
        jdbc.update("update ratings set deleted = true where id = ?", old);
        jdbc.update(insert, UUID.randomUUID(), userId);
        assertThat(ratingRepository.findById(old)).isEmpty();
        assertThat(ratings.getByUserId(userId)).hasSize(2);
        questions.importQuestions(List.of(fixture().getFirst()), false);
        String duplicate = "insert into questions select ?,created_at,updated_at,false,external_key,100,subject,topic,difficulty,prompt,options,correct_option_id,explanation,true from questions limit 1";
        assertThatThrownBy(() -> jdbc.update(duplicate, UUID.randomUUID())).isInstanceOf(DataIntegrityViolationException.class);
        UUID oldQuestion = questionRepository.findAll().getFirst().getId();
        jdbc.update("update questions set deleted = true where id = ?", oldQuestion);
        assertThat(questions.countAvailable(Subject.MATH, Difficulty.MEDIUM)).isZero();
        questions.importQuestions(List.of(fixture().getFirst()), false);
        assertThat(questionRepository.findById(oldQuestion)).isEmpty();
        assertThat(questions.countAvailable(Subject.MATH, Difficulty.MEDIUM)).isEqualTo(1);
    }

    @Test
    void upgradeBackfillsOnlyActiveExistingUsers() {
        var v1 = Flyway.configure().dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())
                .schemas("upgrade_test").target("1").load();
        v1.migrate();
        UUID active = UUID.randomUUID();
        UUID deleted = UUID.randomUUID();
        String sql = "insert into upgrade_test.users(id,created_at,updated_at,deleted,email_normalized,nickname,nickname_normalized,password_hash) values (?,now(),now(),?,?,?,?,'test-only')";
        jdbc.update(sql, active, false, "active@example.com", "Active", "active");
        jdbc.update(sql, deleted, true, "deleted@example.com", "Deleted", "deleted");
        Flyway.configure().dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword()).schemas("upgrade_test").load().migrate();
        assertThat(jdbc.queryForObject("select count(*) from upgrade_test.ratings where user_id = ? and rating = 1000", Integer.class, active)).isEqualTo(2);
        assertThat(jdbc.queryForObject("select count(*) from upgrade_test.ratings where user_id = ?", Integer.class, deleted)).isZero();
    }

    @Test
    void registrationRollsBackUserWhenRatingInitializationFails() {
        RegisterDto registration = new RegisterDto();
        registration.setEmail("rollback-test@example.com");
        registration.setNickname("RollbackTest");
        registration.setPassword("ExamplePass123!");
        doThrow(new IllegalStateException("Test-only rating failure")).when(ratings).initialize(any());
        assertThatThrownBy(() -> auth.register(registration)).isInstanceOf(IllegalStateException.class);
        assertThat(jdbc.queryForObject("select count(*) from users where email_normalized = ?", Integer.class, registration.getEmail())).isZero();
    }

    private QuestionImportResultDto concurrentImport(QuestionImportDto dto, CountDownLatch ready, CountDownLatch start) throws Exception {
        ready.countDown();
        if (!start.await(10, TimeUnit.SECONDS)) throw new IllegalStateException("Import start timed out");
        return questions.importQuestions(List.of(dto), false);
    }

    private List<QuestionImportDto> fixture() throws Exception {
        return files.read(Path.of(Objects.requireNonNull(getClass().getResource("/fixtures/stage2-questions-test-only.json")).toURI()));
    }

    private AuthDto register() {
        String suffix = UUID.randomUUID().toString().replace("-", "").substring(0, 12);
        RegisterDto registration = new RegisterDto();
        registration.setEmail(suffix + "@example.com");
        registration.setNickname("Test_" + suffix);
        registration.setPassword("ExamplePass123!");
        return auth.register(registration);
    }
}
