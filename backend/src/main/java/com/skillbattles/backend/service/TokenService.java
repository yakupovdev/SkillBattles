package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.TokenPairDto;
import java.util.UUID;

public interface TokenService {
    TokenPairDto issue(UUID userId);
    UUID validateRefresh(String token);
    String hash(String token);
}
