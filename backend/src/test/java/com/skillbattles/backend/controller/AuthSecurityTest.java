package com.skillbattles.backend.controller;

import com.skillbattles.backend.config.*;
import com.skillbattles.backend.exception.UnauthorizedException;
import com.skillbattles.backend.handler.SecurityErrorHandler;
import com.skillbattles.backend.mapper.*;
import com.skillbattles.backend.processor.AuthProcessor;
import com.skillbattles.backend.service.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.*;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import java.time.Clock;
import java.util.UUID;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(controllers = {AuthController.class, UserController.class}, properties = {
        "app.jwt.secret=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=", "app.jwt.issuer=skillbattles-test",
        "app.jwt.access-ttl=PT15M", "app.jwt.refresh-ttl=P7D"})
@Import({SecurityConfig.class, JwtConfig.class, SecurityErrorHandler.class, TokenServiceImpl.class,
        UserMapperImpl.class, AuthMapperImpl.class, AuthSecurityTest.TimeConfig.class})
class AuthSecurityTest {
    @Autowired MockMvc mvc;
    @Autowired TokenService tokens;
    @MockitoBean AuthProcessor processor;
    @MockitoBean UserService users;
    @MockitoBean com.skillbattles.backend.processor.ProfileProcessor profiles;
    @MockitoBean RequestRateLimiter limiter;
    @MockitoBean com.skillbattles.backend.processor.AccountProcessor accounts;

    @TestConfiguration
    static class TimeConfig {
        @Bean Clock clock() { return Clock.systemUTC(); }
    }

    @Test
    void protectedEndpointsRequireAccessBearerAndReturnUniformErrors() throws Exception {
        mvc.perform(get("/api/v1/users/me")).andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("UNAUTHORIZED")).andExpect(jsonPath("$.fieldErrors").isArray())
                .andExpect(header().string("WWW-Authenticate", "Bearer")).andExpect(header().doesNotExist("Set-Cookie"));
        mvc.perform(get("/api/v1/users/me").header("Authorization", "Bearer malformed"))
                .andExpect(status().isUnauthorized()).andExpect(jsonPath("$.code").value("UNAUTHORIZED"));
        String refresh = tokens.issue(UUID.randomUUID()).getRefreshToken();
        mvc.perform(get("/api/v1/users/me").header("Authorization", "Bearer " + refresh))
                .andExpect(status().isUnauthorized()).andExpect(jsonPath("$.code").value("UNAUTHORIZED"));
        verifyNoInteractions(users);
    }

    @Test
    void validAccessPassesFilterAndNeverCreatesSession() throws Exception {
        UUID id = UUID.randomUUID();
        com.skillbattles.backend.dto.UserDto user = new com.skillbattles.backend.dto.UserDto();
        user.setId(id);
        when(accounts.state(id)).thenReturn(new com.skillbattles.backend.dto.AccountStateDto(user,null,null,null));
        mvc.perform(get("/api/v1/users/me").header("Authorization", "Bearer " + tokens.issue(id).getAccessToken()))
                .andExpect(status().isOk()).andExpect(jsonPath("$.id").value(id.toString()))
                .andExpect(header().doesNotExist("Set-Cookie"));
    }

    @Test
    void refreshBearerReachesProcessorWithoutAccessValidation() throws Exception {
        String refresh = tokens.issue(UUID.randomUUID()).getRefreshToken();
        mvc.perform(post("/api/v1/auth/logout").header("Authorization", "Bearer " + refresh))
                .andExpect(status().isNoContent()).andExpect(content().string(""));
        verify(processor).logout(refresh);
        mvc.perform(post("/api/v1/auth/refresh").header("Authorization", "Bearer " + refresh)).andExpect(status().isOk());
        verify(processor).refresh(refresh);
    }

    @Test
    void missingOrMalformedRefreshHeaderHasUniformError() throws Exception {
        mvc.perform(post("/api/v1/auth/refresh")).andExpect(status().isUnauthorized()).andExpect(jsonPath("$.code").value("UNAUTHORIZED"));
        mvc.perform(post("/api/v1/auth/logout").header("Authorization", "Bearer a b"))
                .andExpect(status().isUnauthorized()).andExpect(jsonPath("$.code").value("UNAUTHORIZED"));
        verifyNoInteractions(processor);
    }

    @Test
    void publicLoginDoesNotRequireCsrfAndDoesNotLeakCredentials() throws Exception {
        when(processor.login(any())).thenThrow(new UnauthorizedException("INVALID_CREDENTIALS", "Invalid email or password."));
        mvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"alex@example.com\",\"password\":\"WrongPassword123\"}"))
                .andExpect(status().isUnauthorized()).andExpect(jsonPath("$.code").value("INVALID_CREDENTIALS"))
                .andExpect(content().string(org.hamcrest.Matchers.not(org.hamcrest.Matchers.containsString("WrongPassword123"))));
    }

    @Test
    void rejectsUnknownFieldsMalformedJsonAndOverlongUtf8Passwords() throws Exception {
        mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"alex@example.com\",\"password\":\"Password123\",\"birthYear\":2000,\"birthMonth\":1,\"nickname\":\"Alex_One\",\"deleted\":true}"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));
        mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON).content("{"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));
        mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"alex@example.com\",\"password\":\"" + "я".repeat(37) + "\",\"birthYear\":2000,\"birthMonth\":1,\"nickname\":\"Alex_One\"}"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.fieldErrors[0].field").value("password"));
        mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"alex@example.com\",\"password\":\"яяяя\",\"birthYear\":2000,\"birthMonth\":1,\"nickname\":\"Alex_One\"}"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.fieldErrors[0].field").value("password"));
        verifyNoInteractions(processor);
    }
}
