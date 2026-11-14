package com.skillbattles.backend.service;

import com.skillbattles.backend.config.*;
import com.skillbattles.backend.dto.TokenPairDto;
import com.skillbattles.backend.exception.UnauthorizedException;
import org.junit.jupiter.api.*;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.*;
import javax.crypto.SecretKey;
import java.time.*;
import java.util.*;
import static org.assertj.core.api.Assertions.*;

class TokenServiceTest {
    private final Instant now = Instant.parse("2026-11-14T12:00:00Z");
    private final Clock clock = Clock.fixed(now, ZoneOffset.UTC);
    private final UUID userId = UUID.randomUUID();
    private final JwtProperties properties = properties();
    private final JwtConfig config = new JwtConfig();
    private final SecretKey key = config.jwtKey(properties);
    private final JwtEncoder encoder = config.jwtEncoder(key);
    private final JwtDecoder accessDecoder = config.accessJwtDecoder(key, properties, clock);
    private final JwtDecoder refreshDecoder = config.refreshJwtDecoder(key, properties, clock);
    private final TokenService service = new TokenServiceImpl(encoder, refreshDecoder, properties, clock);

    @Test
    void issuesDistinctTypedTokensWithConfiguredExpiryAndUniqueRefreshIds() {
        TokenPairDto pair = service.issue(userId);
        Jwt access = accessDecoder.decode(pair.getAccessToken());
        Jwt refresh = refreshDecoder.decode(pair.getRefreshToken());
        assertThat(access.getSubject()).isEqualTo(userId.toString());
        assertThat(access.getExpiresAt()).isEqualTo(now.plusSeconds(900));
        assertThat(refresh.getExpiresAt()).isEqualTo(now.plusSeconds(604800));
        assertThat(pair.getAccessExpiresIn()).isEqualTo(900);
        assertThat(pair.getRefreshExpiresIn()).isEqualTo(604800);
        assertThat(service.validateRefresh(pair.getRefreshToken())).isEqualTo(userId);
        assertThat(service.issue(userId).getRefreshToken()).isNotEqualTo(pair.getRefreshToken());
        assertThat(service.hash(pair.getRefreshToken())).hasSize(64).doesNotContain(pair.getRefreshToken());
        assertThat(service.hash(pair.getRefreshToken())).isEqualTo(service.hash(pair.getRefreshToken()));
    }

    @Test
    void rejectsMixingTokenTypesInBothDirections() {
        TokenPairDto pair = service.issue(userId);
        assertThatThrownBy(() -> accessDecoder.decode(pair.getRefreshToken())).isInstanceOf(JwtException.class);
        assertThatThrownBy(() -> service.validateRefresh(pair.getAccessToken())).isInstanceOf(UnauthorizedException.class);
    }

    @Test
    void rejectsExpiredTokensAtExactDeadline() {
        TokenPairDto pair = service.issue(userId);
        JwtDecoder expired = config.refreshJwtDecoder(key, properties, Clock.fixed(now.plusSeconds(604800), ZoneOffset.UTC));
        assertThatThrownBy(() -> expired.decode(pair.getRefreshToken())).isInstanceOf(JwtException.class);
    }

    @Test
    void rejectsInvalidSignatureMalformedAndMissingRequiredClaims() {
        JwtProperties otherProperties = properties();
        byte[] otherKey = new byte[32];
        Arrays.fill(otherKey, (byte) 7);
        otherProperties.setSecret(Base64.getEncoder().encodeToString(otherKey));
        TokenService other = new TokenServiceImpl(config.jwtEncoder(config.jwtKey(otherProperties)), refreshDecoder, properties, clock);
        assertThatThrownBy(() -> service.validateRefresh(other.issue(userId).getRefreshToken())).isInstanceOf(UnauthorizedException.class);
        assertThatThrownBy(() -> service.validateRefresh("malformed")).isInstanceOf(UnauthorizedException.class);
        JwtClaimsSet claims = JwtClaimsSet.builder().issuer(properties.getIssuer()).subject(userId.toString())
                .issuedAt(now).claim("token_use", "refresh").build();
        String missing = encoder.encode(JwtEncoderParameters.from(JwsHeader.with(MacAlgorithm.HS256).build(), claims)).getTokenValue();
        assertThatThrownBy(() -> service.validateRefresh(missing)).isInstanceOf(UnauthorizedException.class);
    }

    @Test
    void rejectsWrongIssuerAudienceAndMissingExpiry() {
        for (String scenario : List.of("issuer", "audience", "expiry")) {
            JwtClaimsSet.Builder claims = JwtClaimsSet.builder().issuer(scenario.equals("issuer") ? "other" : properties.getIssuer())
                    .subject(userId.toString()).issuedAt(now).id(UUID.randomUUID().toString()).claim("token_use", "refresh")
                    .audience(List.of(scenario.equals("audience") ? "other" : "skillbattles-refresh"));
            if (!scenario.equals("expiry")) claims.expiresAt(now.plusSeconds(600));
            String token = encoder.encode(JwtEncoderParameters.from(JwsHeader.with(MacAlgorithm.HS256).build(), claims.build())).getTokenValue();
            assertThatThrownBy(() -> service.validateRefresh(token)).as(scenario).isInstanceOf(UnauthorizedException.class);
        }
    }

    @Test
    void refusesShortSigningKeys() {
        properties.setSecret(Base64.getEncoder().encodeToString(new byte[8]));
        assertThatThrownBy(() -> config.jwtKey(properties)).isInstanceOf(IllegalArgumentException.class);
    }

    private static JwtProperties properties() {
        JwtProperties properties = new JwtProperties();
        properties.setSecret(Base64.getEncoder().encodeToString(new byte[32]));
        properties.setIssuer("skillbattles-test");
        properties.setAccessTtl(Duration.ofMinutes(15));
        properties.setRefreshTtl(Duration.ofDays(7));
        return properties;
    }
}
