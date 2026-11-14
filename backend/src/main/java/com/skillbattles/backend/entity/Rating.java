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
    @Column(nullable = false)
    private UUID userId;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private Subject subject;
    @Column(nullable = false)
    private int rating;
}
