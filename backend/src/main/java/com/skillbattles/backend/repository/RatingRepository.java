package com.skillbattles.backend.repository;

import com.skillbattles.backend.entity.Rating;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.repository.query.Param;
import jakarta.persistence.LockModeType;
import java.util.*;

public interface RatingRepository extends JpaRepository<Rating, UUID> {
    List<Rating> findAllByUserId(UUID userId);
    @Modifying
    @Query(value = """
        INSERT INTO ratings (id,created_at,updated_at,deleted,user_id,discipline_code,rating,season_id,calibration_completed_matches,season_peak_rating,all_time_peak_rating)
        VALUES (gen_random_uuid(),timezone('UTC',now()),timezone('UTC',now()),false,:userId,:code,1000,:seasonId,0,1000,1000)
        ON CONFLICT (user_id,discipline_code) WHERE deleted=false DO NOTHING
        """, nativeQuery = true)
    int initializeMissing(@Param("userId") UUID userId, @Param("code") String code,@Param("seasonId") String seasonId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select r from Rating r where r.userId=:userId order by r.disciplineCode")
    List<Rating> lockByUserId(@Param("userId") UUID userId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select r from Rating r where r.userId in :ids and r.disciplineCode = :disciplineCode order by r.userId")
    List<Rating> lockForSettlement(@Param("ids") Collection<UUID> ids, @Param("disciplineCode") String disciplineCode);
}
