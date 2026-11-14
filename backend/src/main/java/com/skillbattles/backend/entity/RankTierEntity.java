package com.skillbattles.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.SQLRestriction;
import org.hibernate.annotations.SQLDelete;

@Getter @Setter @Entity @Table(name = "rank_tiers") @SQLRestriction("deleted = false")
@SQLDelete(sql = "UPDATE rank_tiers SET deleted=true, updated_at=timezone('UTC',now()) WHERE id=?")
public class RankTierEntity extends BaseEntity {
    @Column(nullable = false, unique = true, length = 32) private String code;
    @Column(nullable = false, length = 100) private String displayName;
    @Column(nullable = false, length = 32) private String leagueCode;
    @Column(nullable = false, unique = true) private int floorRating;
    private Integer ceilingExclusive;
    private Integer divisionNumber;
}
