package com.skillbattles.backend.config;

import com.nimbusds.jose.jwk.source.ImmutableSecret;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.*;
import org.springframework.security.oauth2.core.*;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.*;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import java.time.*;
import java.util.*;

@Configuration
@EnableConfigurationProperties(JwtProperties.class)
public class JwtConfig {
    @Bean
    public SecretKey jwtKey(JwtProperties properties) {
        byte[] bytes;
        try { bytes = Base64.getDecoder().decode(properties.getSecret()); }
        catch (IllegalArgumentException ex) { throw new IllegalArgumentException("JWT_SECRET must be Base64 encoded."); }
        if (bytes.length < 32) throw new IllegalArgumentException("JWT_SECRET must contain at least 32 random bytes.");
        return new SecretKeySpec(bytes, "HmacSHA256");
    }

    @Bean
    public JwtEncoder jwtEncoder(SecretKey key) {
        return new NimbusJwtEncoder(new ImmutableSecret<>(key));
    }

    @Bean("accessJwtDecoder")
    public JwtDecoder accessJwtDecoder(SecretKey key, JwtProperties properties, Clock clock) {
        return decoder(key, properties, clock, "access");
    }

    @Bean("refreshJwtDecoder")
    public JwtDecoder refreshJwtDecoder(SecretKey key, JwtProperties properties, Clock clock) {
        return decoder(key, properties, clock, "refresh");
    }

    private JwtDecoder decoder(SecretKey key, JwtProperties properties, Clock clock, String type) {
        NimbusJwtDecoder decoder = NimbusJwtDecoder.withSecretKey(key).macAlgorithm(MacAlgorithm.HS256).build();
        JwtTimestampValidator timestamp = new JwtTimestampValidator(Duration.ZERO);
        timestamp.setClock(clock);
        OAuth2TokenValidator<Jwt> purpose = jwt -> {
            boolean valid = type.equals(jwt.getClaimAsString("token_use"))
                    && jwt.getAudience() != null && jwt.getAudience().contains("skillbattles-" + type)
                    && jwt.getExpiresAt() != null && jwt.getIssuedAt() != null
                    && jwt.getIssuedAt().isBefore(jwt.getExpiresAt())
                    && !jwt.getIssuedAt().isAfter(clock.instant())
                    && jwt.getExpiresAt().isAfter(clock.instant())
                    && jwt.getId() != null;
            try { UUID.fromString(jwt.getSubject()); }
            catch (IllegalArgumentException | NullPointerException ex) { valid = false; }
            return valid ? OAuth2TokenValidatorResult.success()
                    : OAuth2TokenValidatorResult.failure(new OAuth2Error("invalid_token", "Invalid token purpose or claims.", null));
        };
        decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(timestamp, new JwtIssuerValidator(properties.getIssuer()), purpose));
        return decoder;
    }
}
