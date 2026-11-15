package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.*;
import java.util.UUID;

public interface UserService {
    String friendCode(UUID id);
    java.util.Optional<UserDto> findByFriendCode(String code);
    java.util.List<UUID> activeIds();
    UserDto register(RegisterDto dto);
    UserDto authenticate(LoginDto dto);
    UserDto getById(UUID id);
    java.util.List<UserDto> findByIds(java.util.Collection<UUID> ids);
    UserDto lockActiveById(UUID id);
    void softDelete(UUID id);
    UserDto update(UUID id, ProfileUpdateDto dto);
    java.util.Optional<UserDto> findByEmail(String email);
    void resetPassword(UUID id, String password);
}
