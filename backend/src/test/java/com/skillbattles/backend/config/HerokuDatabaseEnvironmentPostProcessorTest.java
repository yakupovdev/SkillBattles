package com.skillbattles.backend.config;

import org.junit.jupiter.api.Test;
import org.springframework.mock.env.MockEnvironment;
import static org.assertj.core.api.Assertions.*;

class HerokuDatabaseEnvironmentPostProcessorTest {
    @Test void decodesUserinfoWithoutTreatingPlusAsSpaceAndRequiresTls() {
        var properties = HerokuDatabaseEnvironmentPostProcessor.datasourceProperties(
                "postgres://user%40name:p%3A%2F%40%25+word@db.example:6543/app?connectTimeout=8");
        assertThat(properties).containsEntry("spring.datasource.username", "user@name")
                .containsEntry("spring.datasource.password", "p:/@%+word")
                .containsEntry("spring.datasource.url", "jdbc:postgresql://db.example:6543/app?connectTimeout=8&sslmode=require");
    }

    @Test void supportsDefaultPortAndStrongerTls() {
        assertThat(HerokuDatabaseEnvironmentPostProcessor.datasourceProperties(
                "postgresql://user:password@db.example/app?sslmode=verify-full"))
                .containsEntry("spring.datasource.url", "jdbc:postgresql://db.example:5432/app?sslmode=verify-full");
    }

    @Test void rejectsInvalidUrisAndCredentialsInQueryWithoutLeakingInputOrCause() {
        for (String value : new String[]{"", "postgres://user:secret@db.example/app?sslmode=disable",
                "jdbc:postgresql://db.example/app", "postgres://user:secret@db.example/app?password=secret",
                "postgres://user:secret@db.example:0/app", "postgres://user:secret@db.example/app#secret",
                "postgres://user:secret with spaces@db.example/app"}) {
            assertThatThrownBy(() -> HerokuDatabaseEnvironmentPostProcessor.datasourceProperties(value))
                    .isInstanceOf(IllegalStateException.class).hasMessageNotContaining("secret").hasNoCause();
        }
    }

    @Test void mapsOnlyHerokuAndOverridesLocalDatabaseProperties() {
        var processor = new HerokuDatabaseEnvironmentPostProcessor();
        var local = new MockEnvironment().withProperty("DB_PASSWORD", "local");
        processor.postProcessEnvironment(local, null);
        assertThat(local.getProperty("spring.datasource.url")).isNull();
        var heroku = new MockEnvironment().withProperty("DATABASE_URL", "postgres://u:p@db.example/app")
                .withProperty("spring.datasource.url", "jdbc:postgresql://localhost/local");
        heroku.setActiveProfiles("heroku");
        processor.postProcessEnvironment(heroku, null);
        assertThat(heroku.getProperty("spring.datasource.url")).isEqualTo("jdbc:postgresql://db.example:5432/app?sslmode=require");
        var missing = new MockEnvironment();
        missing.setActiveProfiles("heroku");
        assertThatThrownBy(() -> processor.postProcessEnvironment(missing, null)).isInstanceOf(IllegalStateException.class);
    }
}
