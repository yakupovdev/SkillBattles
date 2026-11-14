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
    private final AgePolicy agePolicy;
    // Valid BCrypt hash for timing equalisation when an email is unknown.
    private static final String DUMMY_HASH = "$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy";

    @Override
    @Transactional
    public UserDto register(RegisterDto dto) {
        agePolicy.validate(dto.getBirthYear(), dto.getBirthMonth(), dto.getBirthDay());
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

    @Override public Optional<UserDto> findByEmail(String email) { return repository.findByEmailNormalized(email.trim().toLowerCase(Locale.ROOT)).map(mapper::toDto); }
    @Override @Transactional public UserDto update(UUID id, ProfileUpdateDto dto) {
        if(dto.getNickname()==null && dto.getCurrentPassword()==null && dto.getNewPassword()==null)
            throw new BusinessValidationException("EMPTY_UPDATE","Provide a nickname or password change.");
        if((dto.getCurrentPassword()==null)!=(dto.getNewPassword()==null))
            throw new BusinessValidationException("VALIDATION_ERROR","Both currentPassword and newPassword are required.");
        User user=repository.lockById(id).orElseThrow(UnauthorizedException::new);
        if(dto.getNewPassword()!=null) {
            if(!passwordEncoder.matches(dto.getCurrentPassword(),user.getPasswordHash())) throw new UnauthorizedException("INVALID_CURRENT_PASSWORD","Current password is invalid.");
            user.setPasswordHash(passwordEncoder.encode(dto.getNewPassword()));
        }
        if(dto.getNickname()!=null) {
            String normalized=dto.getNickname().toLowerCase(Locale.ROOT);
            if(!normalized.equals(user.getNicknameNormalized()) && repository.existsByNicknameNormalized(normalized)) throw new ConflictException("NICKNAME_ALREADY_EXISTS","Nickname is already in use.");
            user.setNickname(dto.getNickname()); user.setNicknameNormalized(normalized);
        }
        repository.flush(); return mapper.toDto(user);
    }
    @Override @Transactional public void resetPassword(UUID id,String password) {
        var user=repository.lockById(id).orElseThrow(UnauthorizedException::new);
        user.setPasswordHash(passwordEncoder.encode(password)); repository.flush();
    }
    @Override
    @Transactional
    public void softDelete(UUID id) {
        User user = repository.lockById(id).orElseThrow(() -> new NotFoundException("USER_NOT_FOUND", "User not found."));
        user.setDeleted(true);
        repository.flush();
    }
}
