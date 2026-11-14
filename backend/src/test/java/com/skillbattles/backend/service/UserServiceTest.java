package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.User;
import com.skillbattles.backend.exception.*;
import com.skillbattles.backend.mapper.UserMapper;
import com.skillbattles.backend.repository.UserRepository;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;
import java.util.*;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {
    @Mock UserRepository repository;
    @Mock UserMapper mapper;
    @Mock PasswordEncoder passwordEncoder;
    @InjectMocks UserServiceImpl service;

    @Test
    void registrationNormalizesBusinessKeysAndHashesUntrimmedPassword() {
        RegisterDto dto = new RegisterDto();
        dto.setEmail(" Alex@Example.COM ");
        dto.setNickname("Alex_One");
        dto.setPassword(" password ");
        User entity = new User();
        when(mapper.toEntity(dto)).thenReturn(entity);
        when(passwordEncoder.encode(" password ")).thenReturn("encoded-password");
        service.register(dto);
        assertThat(entity.getEmailNormalized()).isEqualTo("alex@example.com");
        assertThat(entity.getNicknameNormalized()).isEqualTo("alex_one");
        assertThat(entity.getPasswordHash()).isEqualTo("encoded-password");
        verify(repository).saveAndFlush(entity);
    }

    @Test
    void duplicateNicknameHasStableConflictAndDoesNotWrite() {
        RegisterDto dto = new RegisterDto();
        dto.setEmail("alex@example.com");
        dto.setNickname("Alex_One");
        when(repository.existsByNicknameNormalized("alex_one")).thenReturn(true);
        assertThatThrownBy(() -> service.register(dto)).isInstanceOfSatisfying(ConflictException.class,
                ex -> assertThat(ex.getCode()).isEqualTo("NICKNAME_ALREADY_EXISTS"));
        verify(repository, never()).saveAndFlush(any());
        verifyNoInteractions(passwordEncoder);
    }

    @Test
    void unknownEmailAndWrongPasswordHaveSameErrorAndBothCheckPassword() {
        LoginDto dto = new LoginDto();
        dto.setEmail("alex@example.com");
        dto.setPassword("wrong-password");
        when(repository.lockByEmail(dto.getEmail())).thenReturn(Optional.empty());
        assertInvalidCredentials(dto);
        User user = new User();
        user.setPasswordHash("stored-hash");
        when(repository.lockByEmail(dto.getEmail())).thenReturn(Optional.of(user));
        assertInvalidCredentials(dto);
        verify(passwordEncoder, times(2)).matches(eq(dto.getPassword()), anyString());
    }

    @Test
    void repeatedSoftDeletionReturnsNotFound() {
        UUID id = UUID.randomUUID();
        when(repository.lockById(id)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.softDelete(id)).isInstanceOf(NotFoundException.class);
    }

    private void assertInvalidCredentials(LoginDto dto) {
        assertThatThrownBy(() -> service.authenticate(dto)).isInstanceOfSatisfying(UnauthorizedException.class,
                ex -> assertThat(ex.getCode()).isEqualTo("INVALID_CREDENTIALS"));
    }
}
