package com.skillbattles.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import java.time.Instant;

@Getter
@AllArgsConstructor
public class TokenPairDto {
    private final String accessToken;
    private final String refreshToken;
    private final long accessExpiresIn;
    private final long refreshExpiresIn;
    private final Instant refreshExpiresAt;
}
