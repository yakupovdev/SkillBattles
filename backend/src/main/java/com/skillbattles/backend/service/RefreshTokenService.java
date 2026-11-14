package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.RefreshTokenDto;
import java.util.UUID;

public interface RefreshTokenService {
    void store(RefreshTokenDto dto);
    void consume(String tokenHash, UUID userId);
    void revokeAll(UUID userId);
}
