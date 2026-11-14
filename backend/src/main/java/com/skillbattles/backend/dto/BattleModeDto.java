package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.Subject;
import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class BattleModeDto {
    private final Subject subject;
    private final int questionCount;
    private final int questionLimitSeconds;
    private final int readyTimeoutSeconds;
    private final int countdownSeconds;
    private final int revealSeconds;
    private final boolean contentAvailable;
}
