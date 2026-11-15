package com.skillbattles.backend.entity;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.SQLRestriction;
import java.time.Instant;
import java.util.UUID;

@Entity @Table(name="friend_relations") @Getter @Setter
@SQLRestriction("deleted=false")
public class FriendRelation extends BaseEntity {
    @Column(nullable=false) private UUID userLowId;
    @Column(nullable=false) private UUID userHighId;
    @Column(nullable=false) private UUID requesterId;
    @Column(nullable=false) private UUID recipientId;
    @Enumerated(EnumType.STRING) @Column(nullable=false,length=16) private FriendStatus status;
    private Instant acceptedAt;
    @Column(nullable=false) private int version;
    @PrePersist @PreUpdate
    private void databasePrecision() {
        // PostgreSQL stores microseconds. Keep first responses/events identical to
        // later idempotent reads instead of exposing pre-flush nanosecond values.
        if(getCreatedAt()!=null)setCreatedAt(getCreatedAt().truncatedTo(java.time.temporal.ChronoUnit.MICROS));
        if(getUpdatedAt()!=null)setUpdatedAt(getUpdatedAt().truncatedTo(java.time.temporal.ChronoUnit.MICROS));
        if(acceptedAt!=null)acceptedAt=acceptedAt.truncatedTo(java.time.temporal.ChronoUnit.MICROS);
    }
}
