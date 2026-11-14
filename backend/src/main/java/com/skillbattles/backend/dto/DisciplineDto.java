package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.util.*;

@Data @NoArgsConstructor @AllArgsConstructor
public class DisciplineDto {
    private String code;
    private String displayName;
    private String description;
    private boolean active;
    private BattleFormat format;
    private QuestionType questionType;
    private int optionsCount;
    private int questionCount;
    private int baseQuestionSeconds;
    private int overtimeSeconds;
    private List<DifficultyTimingDto> timings;
    private List<DifficultyScheduleDto> schedules;
    private List<TopicDto> topics;
}
