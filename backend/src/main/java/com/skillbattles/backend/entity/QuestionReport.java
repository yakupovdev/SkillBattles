package com.skillbattles.backend.entity;
import lombok.*;import jakarta.persistence.*;import java.util.UUID;import org.hibernate.annotations.SQLRestriction;
@Entity @Table(name="question_reports") @Getter @Setter @SQLRestriction("deleted=false")
public class QuestionReport extends BaseEntity { @Column(nullable=false) private UUID userId;@Column(nullable=false) private UUID battleId;@Column(nullable=false) private UUID roundId;@Column(nullable=false,length=32) private String reason;@Column(length=1000) private String comment; }
