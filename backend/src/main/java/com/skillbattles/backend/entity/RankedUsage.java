package com.skillbattles.backend.entity;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.SQLRestriction;
import org.hibernate.annotations.SQLDelete;
import java.time.*;
import java.util.UUID;
@Entity @Table(name="ranked_usage") @Getter @Setter @SQLRestriction("deleted=false")
@SQLDelete(sql="UPDATE ranked_usage SET deleted=true,updated_at=timezone('UTC',now()) WHERE id=?")
public class RankedUsage extends BaseEntity {
    @Column(nullable=false) private UUID userId;
    @Column(nullable=false) private UUID battleId;
    @Column(nullable=false) private LocalDate usageDate;
    @Column(nullable=false) private Instant startedAt;
    @Column(nullable=false) private boolean refunded;
}
