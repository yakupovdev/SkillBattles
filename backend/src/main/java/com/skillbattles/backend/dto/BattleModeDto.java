package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.util.*;

@Getter @Setter
public class BattleModeDto {
    private String disciplineCode;
    private String displayName;
    private String description;
    private boolean active;
    private BattleFormat format;
    private QuestionType questionType;
    private int optionsCount;
    private int questionCount;
    private int baseQuestionSeconds;
    private List<DifficultyTiming> difficultyTimings;
    private List<DifficultySchedule> difficultySchedules;
    private int overtimeSeconds;
    private int readyTimeoutSeconds;
    private int countdownSeconds;
    private int revealSeconds;
    private int reconnectGraceSeconds;
    private boolean contentAvailable;
}
