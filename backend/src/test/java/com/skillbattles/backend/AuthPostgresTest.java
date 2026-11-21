package com.skillbattles.backend;

import com.fasterxml.jackson.databind.*;
import com.skillbattles.backend.processor.AuthProcessor;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.*;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.*;
import java.util.*;
import java.util.concurrent.*;
import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = {"app.jwt.secret=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=", "app.battle.scheduling.enabled=false"})
@AutoConfigureMockMvc
@Testcontainers(disabledWithoutDocker = true)
class AuthPostgresTest {
    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:17.12-alpine");

    @DynamicPropertySource
    static void database(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
    }

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired JdbcTemplate jdbc;
    @Autowired AuthProcessor processor;

    @Test
    void registrationProfileLoginRotationReplayAndLogout() throws Exception {
        JsonNode auth = register();
        String access = auth.path("accessToken").asText();
        String refresh = auth.path("refreshToken").asText();
        String id = auth.path("user").path("id").asText();
        assertThat(auth.path("user").has("passwordHash")).isFalse();
        assertThat(auth.path("user").path("isPro").asBoolean()).isTrue();
        assertThat(jdbc.queryForObject("SELECT pro_active FROM subscription_accounts WHERE user_id=?", Boolean.class, UUID.fromString(id))).isTrue();
        assertThat(auth.path("user").path("createdAt").asText()).endsWith("Z");
        assertThat(auth.path("accessExpiresIn").asLong()).isEqualTo(900);
        assertThat(auth.path("refreshExpiresIn").asLong()).isEqualTo(604800);
        String hash = jdbc.queryForObject("select token_hash from refresh_tokens where user_id = ?", String.class, UUID.fromString(id));
        assertThat(hash).hasSize(64).isNotEqualTo(refresh);
        String passwordHash = jdbc.queryForObject("select password_hash from users where id = ?", String.class, UUID.fromString(id));
        assertThat(passwordHash).startsWith("$2a$").isNotEqualTo("ExamplePass123!");
        mvc.perform(get("/api/v1/users/me").header("Authorization", "Bearer " + access))
                .andExpect(status().isOk()).andExpect(jsonPath("$.id").value(id)).andExpect(jsonPath("$.isPro").value(true)).andExpect(jsonPath("$.passwordHash").doesNotExist());
        JsonNode otherSession = body(mvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content(json.writeValueAsString(Map.of("email", auth.path("user").path("email").asText().toUpperCase(Locale.ROOT), "password", "ExamplePass123!"))))
                .andExpect(status().isOk()).andReturn());
        JsonNode rotated = body(mvc.perform(post("/api/v1/auth/refresh").header("Authorization", "Bearer " + refresh))
                .andExpect(status().isOk()).andReturn());
        assertThat(otherSession.path("user").path("isPro").asBoolean()).isTrue();
        assertThat(rotated.path("user").path("isPro").asBoolean()).isTrue();
        assertThat(rotated.path("refreshToken").asText()).isNotEqualTo(refresh);
        mvc.perform(post("/api/v1/auth/refresh").header("Authorization", "Bearer " + refresh))
                .andExpect(status().isUnauthorized()).andExpect(jsonPath("$.code").value("UNAUTHORIZED"));
        String current = rotated.path("refreshToken").asText();
        mvc.perform(post("/api/v1/auth/logout").header("Authorization", "Bearer " + current))
                .andExpect(status().isNoContent()).andExpect(content().string(""));
        mvc.perform(post("/api/v1/auth/refresh").header("Authorization", "Bearer " + current)).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/v1/auth/logout").header("Authorization", "Bearer " + current)).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/v1/users/me").header("Authorization", "Bearer " + access)).andExpect(status().isOk());
        mvc.perform(post("/api/v1/auth/refresh").header("Authorization", "Bearer " + otherSession.path("refreshToken").asText())).andExpect(status().isOk());
    }

    @Test
    void concurrentRefreshHasExactlyOneWinner() throws Exception {
        String refresh = register().path("refreshToken").asText();
        CountDownLatch ready = new CountDownLatch(2);
        CountDownLatch start = new CountDownLatch(1);
        try (ExecutorService executor = Executors.newFixedThreadPool(2)) {
            Callable<Integer> request = () -> {
                ready.countDown();
                if (!start.await(10, TimeUnit.SECONDS)) throw new IllegalStateException("Refresh start timed out");
                return mvc.perform(post("/api/v1/auth/refresh").header("Authorization", "Bearer " + refresh)).andReturn().getResponse().getStatus();
            };
            Future<Integer> first = executor.submit(request);
            Future<Integer> second = executor.submit(request);
            assertThat(ready.await(10, TimeUnit.SECONDS)).isTrue();
            start.countDown();
            assertThat(List.of(first.get(20, TimeUnit.SECONDS), second.get(20, TimeUnit.SECONDS))).containsExactlyInAnyOrder(200, 401);
        }
    }

    @Test
    void activeUniquenessSoftDeletionAndSessionRevocation() throws Exception {
        JsonNode auth = register();
        String email = auth.path("user").path("email").asText();
        String nickname = auth.path("user").path("nickname").asText();
        String payload = json.writeValueAsString(Map.of("birthYear",2000,"birthMonth",1,"email", email.toUpperCase(Locale.ROOT), "nickname", nickname, "password", "ExamplePass123!"));
        mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON).content(payload))
                .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("EMAIL_ALREADY_EXISTS"));
        mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(
                Map.of("birthYear",2000,"birthMonth",1,"email", "other-" + email, "nickname", nickname.toUpperCase(Locale.ROOT), "password", "ExamplePass123!"))))
                .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("NICKNAME_ALREADY_EXISTS"));
        UUID id = UUID.fromString(auth.path("user").path("id").asText());
        processor.deleteUser(id);
        assertThatThrownBy(() -> processor.deleteUser(id)).isInstanceOf(com.skillbattles.backend.exception.NotFoundException.class);
        assertThat(jdbc.queryForObject("select count(*) from refresh_tokens where user_id = ? and revoked_at is null", Integer.class, id)).isZero();
        mvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content(json.writeValueAsString(Map.of("email", email, "password", "ExamplePass123!"))))
                .andExpect(status().isUnauthorized()).andExpect(jsonPath("$.code").value("INVALID_CREDENTIALS"));
        mvc.perform(post("/api/v1/auth/refresh").header("Authorization", "Bearer " + auth.path("refreshToken").asText())).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/v1/users/me").header("Authorization", "Bearer " + auth.path("accessToken").asText())).andExpect(status().isNotFound());
        mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON).content(payload)).andExpect(status().isCreated());
    }

    @Test
    void tokenTypesCannotBeMixedAndSwaggerIsPublic() throws Exception {
        JsonNode auth = register();
        String access = auth.path("accessToken").asText();
        String refresh = auth.path("refreshToken").asText();
        mvc.perform(get("/api/v1/users/me").header("Authorization", "Bearer " + refresh)).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/v1/auth/refresh").header("Authorization", "Bearer " + access)).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/v1/auth/logout").header("Authorization", "Bearer " + access)).andExpect(status().isUnauthorized());
        mvc.perform(get("/swagger-ui.html")).andExpect(status().is3xxRedirection());
        mvc.perform(get("/swagger-ui/index.html")).andExpect(status().isOk());
        mvc.perform(get("/v3/api-docs")).andExpect(status().isOk())
                .andExpect(jsonPath("$.components.securitySchemes.accessBearer.scheme").value("bearer"))
                .andExpect(jsonPath("$.components.securitySchemes.refreshBearer.scheme").value("bearer"));
    }

    private JsonNode register() throws Exception {
        String suffix = UUID.randomUUID().toString().replace("-", "").substring(0, 12);
        String payload = json.writeValueAsString(Map.of("birthYear",2000,"birthMonth",1,"email", "  " + suffix + "@Example.COM ", "password", "ExamplePass123!", "nickname", "User_" + suffix));
        return body(mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON).content(payload))
                .andExpect(status().isCreated()).andReturn());
    }

    private JsonNode body(MvcResult result) throws Exception { return json.readTree(result.getResponse().getContentAsString()); }
}
