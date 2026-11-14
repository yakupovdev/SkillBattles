package com.skillbattles.backend.entity;

import com.skillbattles.backend.dto.*;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.SQLRestriction;
import org.hibernate.annotations.SQLDelete;
import org.hibernate.type.SqlTypes;
import java.util.*;

@Getter @Setter @Entity @Table(name = "disciplines")
@SQLRestriction("deleted = false")
@SQLDelete(sql = "UPDATE disciplines SET deleted=true, active=false, updated_at=timezone('UTC',now()) WHERE id=?")
public class Discipline extends BaseEntity {
    @Column(nullable = false, unique = true, length = 64, updatable = false) private String code;
    @Column(nullable = false, length = 200) private String displayName;
    @Column(nullable = false, columnDefinition = "text") private String description;
    @Column(nullable = false) private boolean active;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 16) private BattleFormat format;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 32) private QuestionType questionType;
    @Column(nullable = false) private int optionsCount;
    @Column(nullable = false) private int questionCount;
    @Column(nullable = false) private int baseQuestionSeconds;
    @Column(nullable = false) private int overtimeSeconds;
    @Column(nullable = false) private int displayOrder;
    @JdbcTypeCode(SqlTypes.JSON) @Column(nullable = false, columnDefinition = "jsonb") private List<DifficultyTimingDto> timings;
    @JdbcTypeCode(SqlTypes.JSON) @Column(nullable = false, columnDefinition = "jsonb") private List<DifficultyScheduleDto> schedules;
    @JdbcTypeCode(SqlTypes.JSON) @Column(nullable = false, columnDefinition = "jsonb") private List<TopicDto> topics = new ArrayList<>();
}
