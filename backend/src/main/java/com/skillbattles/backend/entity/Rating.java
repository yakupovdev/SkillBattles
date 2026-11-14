package com.skillbattles.backend.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.SQLDelete;
import org.hibernate.annotations.SQLRestriction;
import java.util.UUID;

@Getter
@Setter
@Entity
@Table(name = "ratings")
@SQLRestriction("deleted = false")
@SQLDelete(sql = "UPDATE ratings SET deleted = true, updated_at = timezone('UTC', now()) WHERE id = ?")
public class Rating extends BaseEntity {
    @Column(nullable=false) private java.time.Instant ratingReachedAt=java.time.Instant.now();
    @Column(nullable = false)
    private UUID userId;
    @Column(nullable = false, length = 64)
    private String disciplineCode;
    @Column(nullable = false)
    private int rating;
    @Column(nullable = false)
    private int calibrationCompletedMatches;
    @Column(nullable = false, length = 32)
    private String seasonId;
    @Column(nullable = false)
    private int seasonPeakRating = 1000;
    @Column(nullable = false)
    private int allTimePeakRating = 1000;
}
