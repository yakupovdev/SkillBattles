package com.skillbattles.backend.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.SQLDelete;
import org.hibernate.annotations.SQLRestriction;

@Getter
@Setter
@Entity
@Table(name = "users")
@SQLRestriction("deleted = false")
@SQLDelete(sql = "UPDATE users SET deleted = true, updated_at = timezone('UTC', now()) WHERE id = ?")
public class User extends BaseEntity {
    @Column(length=12) private String friendCode;
    private Integer birthYear;
    private Integer birthMonth;
    private Integer birthDay;
    @Column(nullable = false, length = 254)
    private String emailNormalized;
    @Column(nullable = false, length = 24)
    private String nickname;
    @Column(nullable = false, length = 24)
    private String nicknameNormalized;
    @Column(nullable = false, length = 100)
    private String passwordHash;
}
