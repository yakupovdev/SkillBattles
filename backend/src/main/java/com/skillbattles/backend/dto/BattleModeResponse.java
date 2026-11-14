package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.Subject;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class BattleModeResponse {
    private Subject subject;
    private int questionCount;
    private int questionLimitSeconds;
    private int readyTimeoutSeconds;
    private int countdownSeconds;
    private int revealSeconds;
    @Schema(description = "True when enough active MEDIUM questions exist for this subject; rechecked when starting a battle.")
    private boolean contentAvailable;
}
