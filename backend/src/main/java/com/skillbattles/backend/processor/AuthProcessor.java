package com.skillbattles.backend.processor;

import com.skillbattles.backend.dto.*;
import java.util.UUID;

public interface AuthProcessor {
    AuthDto register(RegisterDto dto);
    AuthDto login(LoginDto dto);
    AuthDto refresh(String refreshToken);
    void logout(String refreshToken);
    void deleteUser(UUID userId);
}
