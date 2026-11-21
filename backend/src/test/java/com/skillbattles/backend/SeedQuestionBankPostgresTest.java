package com.skillbattles.backend;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.*;
import java.util.regex.Pattern;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(properties = {"app.jwt.secret=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
        "app.battle.scheduling.enabled=false", "app.matchmaking.scheduling.enabled=false"})
@AutoConfigureMockMvc
@Testcontainers(disabledWithoutDocker = true)
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
class SeedQuestionBankPostgresTest {
    @Container static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:17.12-alpine");
    @DynamicPropertySource static void database(DynamicPropertyRegistry r) {
        r.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        r.add("spring.datasource.username", POSTGRES::getUsername);
        r.add("spring.datasource.password", POSTGRES::getPassword);
    }
    @Autowired JdbcTemplate jdbc;
    @Autowired ObjectMapper json;

    @Test void all239QuestionsPreserveSourceContentAndAll216RemainingOriginalChoiceSets() throws Exception {
        var math = source("SAT_Questions_Math.md", "cb779fb46ce96a132821f573fb044397fc61e5f91641b2b37d2203fd1372407d");
        var rw = source("SAT_Questions_RW.md", "9102ba7e7c8a663974fac00ebb5b795da620966321b4a2e02ac75cb71d0967f8");
        assertThat(jdbc.queryForObject("SELECT count(*) FROM questions WHERE active AND NOT deleted", Integer.class)).isEqualTo(239);
        Set<String> sourceIds = new HashSet<>();
        int originalChoices = verifySource(math, "SAT_MATH", sourceIds) + verifySource(rw, "SAT_RW", sourceIds);
        assertThat(sourceIds).hasSize(239);
        assertThat(originalChoices).isEqualTo(216);
        assertThat(jdbc.queryForList("""
                SELECT discipline_code,difficulty,count(*) AS count FROM questions
                WHERE active AND NOT deleted GROUP BY discipline_code,difficulty ORDER BY discipline_code,difficulty
                """)).hasSize(6).allSatisfy(row -> assertThat(((Number) row.get("count")).intValue()).isEqualTo(row.get("discipline_code").equals("SAT_MATH") && row.get("difficulty").equals("EASY") ? 39 : 40));
    }

    @Test void migrationsDoNotCreateUserAccounts() {
        assertThat(jdbc.queryForObject("SELECT count(*) FROM users", Integer.class)).isZero();
        assertThat(jdbc.queryForObject("SELECT count(*) FROM subscription_accounts", Integer.class)).isZero();
    }

    @Test void repeatedStartupDoesNotDuplicateOrResetSeededRows() {
        var before = jdbc.queryForList("SELECT row_to_json(q)::text FROM questions q ORDER BY external_key");
        var users = jdbc.queryForList("SELECT row_to_json(u)::text FROM users u ORDER BY email_normalized");
        var flyway = Flyway.configure().dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword()).load();
        assertThat(flyway.migrate().migrationsExecuted).isZero();
        flyway.validate();
        assertThat(jdbc.queryForList("SELECT row_to_json(q)::text FROM questions q ORDER BY external_key")).isEqualTo(before);
        assertThat(jdbc.queryForList("SELECT row_to_json(u)::text FROM users u ORDER BY email_normalized")).isEqualTo(users);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM subscription_accounts", Integer.class)).isZero();
    }

    private String source(String file, String sha256) throws Exception {
        byte[] bytes;
        try (var input = getClass().getResourceAsStream("/question-bank/" + file)) {
            assertThat(input).isNotNull(); bytes = input.readAllBytes();
        }
        assertThat(HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes))).isEqualTo(sha256);
        return new String(bytes, StandardCharsets.UTF_8).replace("\r\n", "\n");
    }

    private int verifySource(String markdown, String discipline, Set<String> ids) throws Exception {
        var heading = Pattern.compile("(?m)^### Question (\\d+) \\(ID: ([^)]+)\\)\\s*$").matcher(markdown);
        List<Integer> starts = new ArrayList<>(); List<Integer> ends = new ArrayList<>(); List<String> keys = new ArrayList<>();
        while (heading.find()) { starts.add(heading.start()); ends.add(heading.end()); keys.add(heading.group(2)); }
        assertThat(keys).hasSize(120);
        int originals = 0;
        for (int i = 0; i < keys.size(); i++) {
            String sourceId = keys.get(i);
            if (discipline.equals("SAT_MATH") && sourceId.equals("15ce8207")) {
                assertThat(jdbc.queryForObject("SELECT count(*) FROM questions WHERE external_key=?", Integer.class, discipline + ":" + sourceId)).isZero();
                continue;
            }
            assertThat(ids.add(sourceId)).isTrue();
            String body = markdown.substring(ends.get(i), i+1 < starts.size() ? starts.get(i+1) : markdown.length());
            int separator = body.indexOf("\n---");
            if (separator >= 0) body = body.substring(0, separator);
            String externalKey = discipline + ":" + sourceId;
            var row = jdbc.queryForMap("SELECT * FROM questions WHERE external_key=? AND content_version=1", externalKey);
            assertThat(row.get("difficulty")).isEqualTo(extract(body, "(?m)^- \\*\\*Difficulty:\\*\\* (.+)$"));
            String domain = extract(body, "(?m)^- \\*\\*Domain:\\*\\* (.+)$");
            String skill = extract(body, "(?m)^- \\*\\*Skill:\\*\\* (.+)$");
            assertThat(row.get("topic_name")).isEqualTo(domain + " / " + skill);
            assertThat(row.get("prompt")).isEqualTo(extract(body, "(?ms)^#### Question\\s*\\n(.*?)(?=^#### Choices|^\\*\\*Correct Answer:)"));
            assertThat(row.get("explanation")).isEqualTo(extract(body, "(?ms)^#### Rationale\\s*\\n(.*)"));
            String answer = extract(body, "(?m)^\\*\\*Correct Answer:\\*\\* (.+)$").replaceFirst("^\\*\\*([^*]+)\\*\\*$", "$1");
            JsonNode options = json.readTree(row.get("options").toString());
            assertThat(options).hasSize(4);
            Set<String> texts = new HashSet<>();
            JsonNode correct = null;
            for (int n = 0; n < 4; n++) {
                var option = options.get(n);
                String key = "ABCD".substring(n,n+1);
                assertThat(option.path("key").asText()).isEqualTo(key);
                assertThat(texts.add(option.path("text").asText())).isTrue();
                String name = "skillbattles:question:" + externalKey.length() + ":" + externalKey + ":1:" + key;
                assertThat(option.path("id").asText()).isEqualTo(UUID.nameUUIDFromBytes(name.getBytes(StandardCharsets.UTF_8)).toString());
                if (option.path("id").asText().equals(row.get("correct_option_id").toString())) correct = option;
            }
            assertThat(correct).isNotNull();
            if (body.contains("#### Choices")) {
                originals++;
                assertThat(correct.path("key").asText()).isEqualTo(answer);
                String choices = extract(body, "(?ms)^#### Choices\\s*\\n(.*?)^\\*\\*Correct Answer:");
                var entries = Pattern.compile("(?ms)^- \\*\\*([ABCD])\\.\\*\\*\\s*(.*?)(?=^- \\*\\*[ABCD]\\.\\*\\*|\\z)").matcher(choices);
                int count = 0;
                while (entries.find()) {
                    assertThat(options.get(count).path("key").asText()).isEqualTo(entries.group(1));
                    assertThat(options.get(count).path("text").asText()).isEqualTo(entries.group(2).strip());
                    count++;
                }
                assertThat(count).isEqualTo(4);
            } else {
                assertThat(correct.path("text").asText()).isEqualTo(answer);
            }
        }
        return originals;
    }

    private String extract(String source, String expression) {
        var match = Pattern.compile(expression).matcher(source);
        assertThat(match.find()).as(expression).isTrue();
        return match.group(1).strip();
    }
}
