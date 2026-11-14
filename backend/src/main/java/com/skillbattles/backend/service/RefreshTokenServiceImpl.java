package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.RefreshTokenDto;
import com.skillbattles.backend.exception.UnauthorizedException;
import com.skillbattles.backend.mapper.RefreshTokenMapper;
import com.skillbattles.backend.repository.RefreshTokenRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional
public class RefreshTokenServiceImpl implements RefreshTokenService {
    private final RefreshTokenRepository repository;
    private final RefreshTokenMapper mapper;
    private final Clock clock;

    @Override
    public void store(RefreshTokenDto dto) { repository.save(mapper.toEntity(dto)); }

    @Override
    public void consume(String tokenHash, UUID userId) {
        Instant now = clock.instant();
        if (repository.consume(tokenHash, userId, now, LocalDateTime.ofInstant(now, ZoneOffset.UTC)) != 1) {
            throw new UnauthorizedException();
        }
    }

    @Override
    public void revokeAll(UUID userId) {
        Instant now = clock.instant();
        repository.revokeAll(userId, now, LocalDateTime.ofInstant(now, ZoneOffset.UTC));
    }
}
