package com.skillbattles.backend.config;

import jakarta.validation.constraints.Min;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

@Getter
@Setter
@Validated
@ConfigurationProperties(prefix = "app.realtime")
public class RealtimeProperties {
    @Min(1) private long heartbeatMs = 5000;
    @Min(1) private long readTimeoutMs = 10000;
    @Min(1) private long connectTimeoutMs = 10000;
    @Min(1) private long monitorMs = 500;
}
