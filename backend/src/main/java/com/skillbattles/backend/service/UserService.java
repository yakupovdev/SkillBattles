package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.*;
import java.util.UUID;

public interface UserService {
    UserDto register(RegisterDto dto);
    UserDto authenticate(LoginDto dto);
    UserDto getById(UUID id);
    UserDto lockActiveById(UUID id);
    void softDelete(UUID id);
}
