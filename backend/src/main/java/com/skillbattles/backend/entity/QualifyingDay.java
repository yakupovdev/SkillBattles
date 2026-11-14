package com.skillbattles.backend.entity;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.SQLRestriction;
import org.hibernate.annotations.SQLDelete;
import java.time.LocalDate;
import java.util.UUID;
@Entity @Table(name="qualifying_days") @Getter @Setter @SQLRestriction("deleted=false")
@SQLDelete(sql="UPDATE qualifying_days SET deleted=true,updated_at=timezone('UTC',now()) WHERE id=?")
public class QualifyingDay extends BaseEntity {
    @Column(nullable=false) private UUID userId;
    @Column(nullable=false) private LocalDate activityDate;
}
