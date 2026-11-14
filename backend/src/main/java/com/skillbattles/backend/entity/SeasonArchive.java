package com.skillbattles.backend.entity;
import com.skillbattles.backend.dto.SeasonDto;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.SQLRestriction;
import org.hibernate.annotations.SQLDelete;
import org.hibernate.type.SqlTypes;
import java.util.UUID;
@Entity @Table(name="season_archives") @Getter @Setter
@SQLRestriction("deleted = false")
@SQLDelete(sql="UPDATE season_archives SET deleted=true, updated_at=timezone('UTC',now()) WHERE id=?")
public class SeasonArchive extends BaseEntity {
    @Column(nullable=false) private UUID userId;
    @Column(nullable=false,length=32) private String seasonId;
    @JdbcTypeCode(SqlTypes.JSON) @Column(nullable=false,columnDefinition="jsonb") private SeasonDto season;
    @Column(nullable=false,length=64) private String disciplineCode;
    @Column(nullable=false) private java.time.Instant seasonStartsAt;
    @Column(nullable=false) private int peakRating;
    @Column(nullable=false,length=32) private String peakRankCode;
    @Column(nullable=false) private int finalRating;
}
