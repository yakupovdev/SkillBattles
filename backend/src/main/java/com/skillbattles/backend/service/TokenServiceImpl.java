package com.skillbattles.backend.service;

import com.skillbattles.backend.config.JwtProperties;
import com.skillbattles.backend.dto.TokenPairDto;
import com.skillbattles.backend.exception.UnauthorizedException;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.*;
import org.springframework.stereotype.Service;
import java.nio.charset.StandardCharsets;
import java.security.*;
import java.time.*;
import java.util.*;

@Service
public class TokenServiceImpl implements TokenService {
    private final JwtEncoder encoder;
    private final JwtDecoder refreshDecoder;
    private final JwtProperties properties;
    private final Clock clock;

    public TokenServiceImpl(JwtEncoder encoder, @Qualifier("refreshJwtDecoder") JwtDecoder refreshDecoder,
                            JwtProperties properties, Clock clock) {
        this.encoder = encoder;
        this.refreshDecoder = refreshDecoder;
        this.properties = properties;
        this.clock = clock;
    }

    @Override
    public TokenPairDto issue(UUID userId) {
        Instant now = clock.instant().truncatedTo(java.time.temporal.ChronoUnit.SECONDS);
        return new TokenPairDto(encode(userId, now, properties.getAccessTtl(), "access"),
                encode(userId, now, properties.getRefreshTtl(), "refresh"),
                properties.getAccessTtl().toSeconds(), properties.getRefreshTtl().toSeconds(), now.plus(properties.getRefreshTtl()));
    }

    private String encode(UUID userId, Instant now, Duration ttl, String type) {
        JwtClaimsSet claims = JwtClaimsSet.builder().issuer(properties.getIssuer()).subject(userId.toString())
                .audience(List.of("skillbattles-" + type)).issuedAt(now).notBefore(now).expiresAt(now.plus(ttl))
                .id(UUID.randomUUID().toString()).claim("token_use", type).build();
        return encoder.encode(JwtEncoderParameters.from(JwsHeader.with(MacAlgorithm.HS256).build(), claims)).getTokenValue();
    }

    @Override
    public UUID validateRefresh(String token) {
        try { return UUID.fromString(refreshDecoder.decode(token).getSubject()); }
        catch (JwtException | IllegalArgumentException ex) { throw new UnauthorizedException(); }
    }

    @Override
    public String hash(String token) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(token.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException ex) { throw new IllegalStateException("SHA-256 is unavailable.", ex); }
    }
}
