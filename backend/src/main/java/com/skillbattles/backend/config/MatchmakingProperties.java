package com.skillbattles.backend.config;

import jakarta.validation.constraints.Min;
import lombok.*;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

@Getter @Setter @Validated
@ConfigurationProperties(prefix = "app.matchmaking")
public class MatchmakingProperties {
    @Min(1) private int searchSeconds = 90;
    @Min(1) private int duelSeconds = 600;
}
