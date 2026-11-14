package com.skillbattles.backend;

import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@Testcontainers(disabledWithoutDocker = true)
class SeedMigrationSafetyPostgresTest {
    @Container static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:17.12-alpine");
    private final JdbcTemplate jdbc = new JdbcTemplate(new DriverManagerDataSource(
            POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword()));

    @Test void cleanDatabaseAppliesExactlyV1ThroughV13WithoutABaseline() {
        assertThat(flyway("fresh_install", "13").migrate().migrationsExecuted).isEqualTo(13);
        assertThat(jdbc.queryForList("SELECT version::int FROM fresh_install.flyway_schema_history WHERE version IS NOT NULL ORDER BY installed_rank", Integer.class))
                .containsExactly(1,2,3,4,5,6,7,8,9,10,11,12,13);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM fresh_install.flyway_schema_history WHERE type='SQL_BASELINE'", Integer.class)).isZero();
        assertThat(jdbc.queryForObject("SELECT to_regclass('fresh_install.practice_sessions')::text", String.class)).isNull();
        assertThat(jdbc.queryForObject("SELECT count(*) FROM fresh_install.questions", Integer.class)).isEqualTo(240);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM fresh_install.users", Integer.class)).isEqualTo(2);
        assertThat(flyway("fresh_install", "13").migrate().migrationsExecuted).isZero();
    }

    @Test void seedUpgradePreservesExistingDataAndAppliedMigrationChecksums() {
        flyway("seed_upgrade", "11").migrate();
        jdbc.update("""
                INSERT INTO seed_upgrade.users(id,created_at,updated_at,email_normalized,nickname,nickname_normalized,password_hash)
                VALUES ('00000000-0000-0000-0000-000000000002',now(),now(),'keep@example.com','Keep','keep','original hash')
                """);
        jdbc.update("""
                INSERT INTO seed_upgrade.questions(id,created_at,updated_at,external_key,content_version,discipline_code,
                    topic_code,topic_name,difficulty,prompt,options,correct_option_id,explanation,active)
                VALUES (gen_random_uuid(),now(),now(),'keep-existing-question',1,'SAT_MATH','KEEP','Keep','EASY',
                    'Original prompt','[{},{},{},{}]'::jsonb,gen_random_uuid(),'Original explanation',true)
                """);
        var users = jdbc.queryForList("SELECT row_to_json(u)::text FROM seed_upgrade.users u");
        var questions = jdbc.queryForList("SELECT row_to_json(q)::text FROM seed_upgrade.questions q");
        var history = jdbc.queryForList("SELECT version,checksum FROM seed_upgrade.flyway_schema_history ORDER BY installed_rank");
        var catalogue = jdbc.queryForList("SELECT (to_jsonb(d)-'topics'-'updated_at')::text FROM seed_upgrade.disciplines d ORDER BY code");
        var latest = flyway("seed_upgrade", "13");
        assertThat(latest.migrate().migrationsExecuted).isEqualTo(2);
        assertThat(jdbc.queryForList("SELECT row_to_json(u)::text FROM seed_upgrade.users u WHERE email_normalized='keep@example.com'")).isEqualTo(users);
        assertThat(jdbc.queryForList("SELECT row_to_json(q)::text FROM seed_upgrade.questions q WHERE external_key='keep-existing-question'")).isEqualTo(questions);
        assertThat(jdbc.queryForList("SELECT version,checksum FROM seed_upgrade.flyway_schema_history WHERE version::integer<=11 OR version IS NULL ORDER BY installed_rank")).isEqualTo(history);
        assertThat(jdbc.queryForList("SELECT (to_jsonb(d)-'topics'-'updated_at')::text FROM seed_upgrade.disciplines d ORDER BY code")).isEqualTo(catalogue);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM seed_upgrade.questions", Integer.class)).isEqualTo(241);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM seed_upgrade.users", Integer.class)).isEqualTo(3);
        assertThat(latest.migrate().migrationsExecuted).isZero();
        latest.validate();
    }

    @Test void conflictingBankAbortsWithoutOverwritingAnyExistingContent() {
        flyway("question_collision", "11").migrate();
        jdbc.update("""
                INSERT INTO question_collision.questions(id,created_at,updated_at,external_key,content_version,discipline_code,
                    topic_code,topic_name,difficulty,prompt,options,correct_option_id,explanation,active)
                VALUES (gen_random_uuid(),now(),now(),'SAT_MATH:ac472881',1,'SAT_MATH','KEEP','Keep','EASY',
                    'Do not replace','[{},{},{},{}]'::jsonb,gen_random_uuid(),'Original explanation',true)
                """);
        var before = jdbc.queryForList("SELECT row_to_json(q)::text FROM question_collision.questions q");
        assertThatThrownBy(() -> flyway("question_collision", "12").migrate()).hasStackTraceContaining("no questions were replaced");
        assertThat(jdbc.queryForList("SELECT row_to_json(q)::text FROM question_collision.questions q")).isEqualTo(before);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM question_collision.users", Integer.class)).isZero();
    }

    @Test void existingEmailNeverGetsItsPasswordOrSubscriptionReplacedByDemoSeed() {
        flyway("account_collision", "12").migrate();
        jdbc.update("""
                INSERT INTO account_collision.users(id,created_at,updated_at,email_normalized,nickname,nickname_normalized,password_hash)
                VALUES (gen_random_uuid(),now(),now(),'admin@gmail.com','Existing','existing','keep existing password')
                """);
        var before = jdbc.queryForList("SELECT row_to_json(u)::text FROM account_collision.users u");
        assertThatThrownBy(() -> flyway("account_collision", "13").migrate()).hasStackTraceContaining("no account was changed");
        assertThat(jdbc.queryForList("SELECT row_to_json(u)::text FROM account_collision.users u")).isEqualTo(before);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM account_collision.subscription_accounts", Integer.class)).isZero();
    }

    private Flyway flyway(String schema, String target) {
        return Flyway.configure().dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())
                .schemas(schema).target(target).load();
    }
}
