package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.User;
import com.skillbattles.backend.exception.*;
import com.skillbattles.backend.mapper.UserMapper;
import com.skillbattles.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserServiceImpl implements UserService {
    @Override public java.util.List<UUID> activeIds() { return repository.activeIds(); }
    private final UserRepository repository;
    private final UserMapper mapper;
    private final PasswordEncoder passwordEncoder;
    // Valid BCrypt hash for timing equalisation when an email is unknown.
    private static final String DUMMY_HASH = "$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy";

    @Override
    @Transactional
    public UserDto register(RegisterDto dto) {
        String email = dto.getEmail().trim().toLowerCase(Locale.ROOT);
        String nickname = dto.getNickname().toLowerCase(Locale.ROOT);
        if (repository.existsByEmailNormalized(email)) {
            throw new ConflictException("EMAIL_ALREADY_EXISTS", "Email is already in use.");
        }
        if (repository.existsByNicknameNormalized(nickname)) {
            throw new ConflictException("NICKNAME_ALREADY_EXISTS", "Nickname is already in use.");
        }
        User user = mapper.toEntity(dto);
        user.setEmailNormalized(email);
        user.setNicknameNormalized(nickname);
        user.setPasswordHash(passwordEncoder.encode(dto.getPassword()));
        return mapper.toDto(repository.saveAndFlush(user));
    }

    @Override
    @Transactional
    public UserDto authenticate(LoginDto dto) {
        Optional<User> user = repository.lockByEmail(dto.getEmail().trim().toLowerCase(Locale.ROOT));
        boolean matches = passwordEncoder.matches(dto.getPassword(), user.map(User::getPasswordHash).orElse(DUMMY_HASH));
        if (user.isEmpty() || !matches) {
            throw new UnauthorizedException("INVALID_CREDENTIALS", "Invalid email or password.");
        }
        return mapper.toDto(user.orElseThrow());
    }

    @Override
    public UserDto getById(UUID id) {
        return mapper.toDto(repository.findById(id).orElseThrow(() -> new NotFoundException("USER_NOT_FOUND", "User not found.")));
    }

    @Override
    @Transactional
    public UserDto lockActiveById(UUID id) {
        return mapper.toDto(repository.lockById(id).orElseThrow(UnauthorizedException::new));
    }

    @Override
    @Transactional
    public void softDelete(UUID id) {
        User user = repository.lockById(id).orElseThrow(() -> new NotFoundException("USER_NOT_FOUND", "User not found."));
        user.setDeleted(true);
        repository.flush();
    }
}
