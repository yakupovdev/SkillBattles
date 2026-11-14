package com.skillbattles.backend.config;

import com.skillbattles.backend.entity.Subject;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

@Getter
@Setter
@Validated
@ConfigurationProperties(prefix = "app.battle")
public class BattleProperties {
    @Valid @NotNull
    private SubjectSettings math;
    @Valid @NotNull
    private SubjectSettings english;
    @Min(1)
    private int readyTimeoutSeconds;
    @Min(1)
    private int countdownSeconds;
    @Min(1)
    private int revealSeconds;
    @Min(1)
    private int reconnectGraceSeconds = 30;
    @Min(1)
    private int questionHistoryBattles = 5;

    public SubjectSettings forSubject(Subject subject) { return subject == Subject.MATH ? math : english; }

    @Getter
    @Setter
    public static class SubjectSettings {
        @Min(1)
        private int questionCount;
        @Min(1)
        private int questionLimitSeconds;
    }
}
