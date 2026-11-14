package com.skillbattles.backend.config;

import jakarta.validation.constraints.*;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;
import java.time.Duration;

@Getter
@Setter
@Validated
@ConfigurationProperties(prefix = "app.jwt")
public class JwtProperties {
    @NotBlank
    private String secret;
    @NotBlank
    private String issuer;
    @NotNull
    private Duration accessTtl;
    @NotNull
    private Duration refreshTtl;

    @AssertTrue(message = "JWT lifetimes must contain positive whole seconds; access must not exceed 15 minutes.")
    public boolean isLifetimeValid() {
        return valid(accessTtl) && valid(refreshTtl) && accessTtl.compareTo(Duration.ofMinutes(15)) <= 0;
    }

    private boolean valid(Duration value) {
        return value != null && value.getSeconds() > 0 && value.getNano() == 0;
    }
}
