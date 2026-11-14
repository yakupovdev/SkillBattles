package com.skillbattles.backend.entity;
import jakarta.persistence.*;
import lombok.*;
import java.time.Instant;
import java.util.UUID;
import org.hibernate.annotations.SQLRestriction;
@Entity @Table(name="password_reset_tokens") @Getter @Setter @SQLRestriction("deleted=false")
public class PasswordResetToken extends BaseEntity {
 @Column(nullable=false) private UUID userId;
 @Column(nullable=false,length=64) private String tokenHash;
 @Column(nullable=false) private Instant expiresAt;
 private Instant consumedAt;
}
