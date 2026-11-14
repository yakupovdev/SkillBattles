package com.skillbattles.backend.processor;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.exception.UnauthorizedException;
import com.skillbattles.backend.service.*;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import java.time.Instant;
import java.util.UUID;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthProcessorTest {
    @Mock UserService users;
    @Mock RefreshTokenService refreshTokens;
    @Mock TokenService tokens;
    @Mock RatingService ratings;
    @InjectMocks AuthProcessorImpl processor;

    @Test
    void registrationInitializesRatingsBeforeIssuingTokens() {
        RegisterDto registration = new RegisterDto();
        UserDto user = new UserDto();
        UUID id = UUID.randomUUID();
        user.setId(id);
        when(users.register(registration)).thenReturn(user);
        when(tokens.issue(id)).thenReturn(new TokenPairDto("access", "refresh", 900, 604800, Instant.MAX));
        processor.register(registration);
        InOrder order = inOrder(users, ratings, tokens);
        order.verify(users).register(registration);
        order.verify(ratings).initialize(id);
        order.verify(tokens).issue(id);
    }

    @Test
    void refreshConsumesOldHashBeforeIssuingNewPair() {
        UUID id = UUID.randomUUID();
        UserDto user = new UserDto();
        user.setId(id);
        when(tokens.validateRefresh("old-token")).thenReturn(id);
        when(users.lockActiveById(id)).thenReturn(user);
        when(tokens.hash("old-token")).thenReturn("old-hash");
        when(tokens.issue(id)).thenReturn(new TokenPairDto("access", "refresh", 900, 604800, Instant.MAX));
        when(tokens.hash("refresh")).thenReturn("new-hash");
        assertThat(processor.refresh("old-token").getUser()).isSameAs(user);
        InOrder order = inOrder(users, refreshTokens, tokens);
        order.verify(tokens).validateRefresh("old-token");
        order.verify(users).lockActiveById(id);
        order.verify(tokens).hash("old-token");
        order.verify(refreshTokens).consume("old-hash", id);
        order.verify(tokens).issue(id);
        ArgumentCaptor<RefreshTokenDto> saved = ArgumentCaptor.forClass(RefreshTokenDto.class);
        verify(refreshTokens).store(saved.capture());
        assertThat(saved.getValue().getTokenHash()).isEqualTo("new-hash");
    }

    @Test
    void replayNeverIssuesAnotherPair() {
        UUID id = UUID.randomUUID();
        when(tokens.validateRefresh("old-token")).thenReturn(id);
        when(users.lockActiveById(id)).thenReturn(new UserDto());
        when(tokens.hash("old-token")).thenReturn("old-hash");
        doThrow(new UnauthorizedException()).when(refreshTokens).consume("old-hash", id);
        assertThatThrownBy(() -> processor.refresh("old-token")).isInstanceOf(UnauthorizedException.class);
        verify(tokens, never()).issue(any());
        verify(refreshTokens, never()).store(any());
    }

    @Test
    void deletingUserRevokesAllSessionsAfterUserLock() {
        UUID id = UUID.randomUUID();
        processor.deleteUser(id);
        InOrder order = inOrder(users, refreshTokens);
        order.verify(users).softDelete(id);
        order.verify(refreshTokens).revokeAll(id);
    }
}
