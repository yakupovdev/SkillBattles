package com.skillbattles.backend.entity;

import com.skillbattles.backend.dto.*;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.SQLDelete;
import org.hibernate.annotations.SQLRestriction;
import org.hibernate.type.SqlTypes;
import java.time.Instant;
import java.util.UUID;

@Getter
@Setter
@Entity
@Table(name = "battles")
@SQLRestriction("deleted = false")
@SQLDelete(sql = "UPDATE battles SET deleted = true, updated_at = timezone('UTC', now()) WHERE id = ?")
public class Battle extends BaseEntity {
    @Column(nullable = false)
    private UUID firstUserId;
    @Column(nullable = false)
    private UUID secondUserId;
    @Column(nullable = false, length = 64)
    private String disciplineCode;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 16)
    private BattleFormat format = BattleFormat.STANDARD;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private BattleMode mode;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private BattlePhase phase;
    @Column(nullable = false)
    private int version;
    private Instant readyDeadline;
    private Instant countdownEndsAt;
    private Instant nextRoundStartsAt;
    private Instant nextTransitionAt;
    private Instant settledAt;
    private Instant finishedAt;
    private UUID winnerUserId;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(nullable = false, columnDefinition = "jsonb")
    private BattleStateDto state;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb")
    private BattleResultDataDto result;
}
