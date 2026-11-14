package com.skillbattles.backend.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.SQLDelete;
import org.hibernate.annotations.SQLRestriction;
import org.hibernate.type.SqlTypes;
import java.util.*;

@Getter
@Setter
@Entity
@Table(name = "questions")
@SQLRestriction("deleted = false")
@SQLDelete(sql = "UPDATE questions SET deleted = true, active = false, updated_at = timezone('UTC', now()) WHERE id = ?")
public class Question extends BaseEntity {
    @Column(nullable = false, length = 200)
    private String externalKey;
    @Column(nullable = false)
    private int contentVersion;
    @Column(nullable = false, length = 64)
    private String disciplineCode;
    @Column(nullable = false, length = 64)
    private String topicCode;
    @Column(nullable = false, length = 200)
    private String topicName;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private Difficulty difficulty;
    @Column(nullable = false, columnDefinition = "text")
    private String prompt;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(nullable = false, columnDefinition = "jsonb")
    private List<QuestionOption> options;
    @Column(nullable = false)
    private UUID correctOptionId;
    @Column(nullable = false, columnDefinition = "text")
    private String explanation;
    @Column(nullable = false)
    private boolean active;
}
