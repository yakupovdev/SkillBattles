package com.skillbattles.backend.controller;

import com.skillbattles.backend.config.*;
import com.skillbattles.backend.handler.SecurityErrorHandler;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import java.time.Clock;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(controllers = HerokuFrontendController.class, properties = {
        "DATABASE_URL=postgres://test:test@db.example/test", "PORT=0"})
@ActiveProfiles("heroku")
@Import({HerokuFrontendConfig.class, SecurityConfig.class, SecurityErrorHandler.class})
class HerokuFrontendTest {
    @Autowired MockMvc mvc;
    @MockitoBean(name = "accessJwtDecoder") JwtDecoder decoder;
    @MockitoBean Clock clock;

    @BeforeEach void time() {
        org.mockito.Mockito.when(clock.instant()).thenReturn(java.time.Instant.parse("2026-11-15T00:00:00Z"));
    }

    @Test void directClientRoutesArePublicAndHaveIsolationHeaders() throws Exception {
        for (String path : new String[]{"/", "/auth", "/auth/reset", "/billing/return", "/play/duel",
                "/profile/edit", "/battle/12345678-1234-1234-1234-123456789012",
                "/friends", "/friends/12345678-1234-1234-1234-123456789012"}) {
            mvc.perform(get(path)).andExpect(status().isOk()).andExpect(forwardedUrl("/index.html"))
                    .andExpect(header().string("Cross-Origin-Opener-Policy", "same-origin"))
                    .andExpect(header().string("Cross-Origin-Embedder-Policy", "require-corp"));
        }
    }

    @Test void apiAndUnknownAssetsNeverBecomeTheFrontend() throws Exception {
        mvc.perform(get("/api/v1/users/me")).andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("UNAUTHORIZED"));
        mvc.perform(get("/api/v1/missing")).andExpect(status().isUnauthorized());
        for (String path : new String[]{"/assets/missing.js", "/main.missing.wasm", "/unknown", "/media/questions/missing.png"}) {
            mvc.perform(get(path)).andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value("NOT_FOUND"));
        }
        mvc.perform(post("/profile")).andExpect(status().isUnauthorized());
    }
}
