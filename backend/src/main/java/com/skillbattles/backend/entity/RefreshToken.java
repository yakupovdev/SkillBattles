package com.skillbattles.backend.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.SQLDelete;
import org.hibernate.annotations.SQLRestriction;
import java.time.Instant;
import java.util.UUID;

@Getter
@Setter
@Entity
@Table(name = "refresh_tokens")
@SQLRestriction("deleted = false")
@SQLDelete(sql = "UPDATE refresh_tokens SET deleted = true, updated_at = timezone('UTC', now()) WHERE id = ?")
public class RefreshToken extends BaseEntity {
    @Column(nullable = false)
    private UUID userId;
    @Column(nullable = false, unique = true, length = 64)
    private String tokenHash;
    @Column(nullable = false)
    private Instant expiresAt;
    private Instant revokedAt;
}
