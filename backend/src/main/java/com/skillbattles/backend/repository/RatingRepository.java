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
    @Query(value="select r.user_id from ratings r join users u on u.id=r.user_id and u.deleted=false where r.deleted=false and r.discipline_code=:code and r.season_id<>:season order by r.user_id",nativeQuery=true)
    List<UUID> rolloverCandidates(@Param("code")String code,@Param("season")String season);
    @Query(value="""
      WITH ranked AS (SELECT row_number() OVER(ORDER BY r.rating DESC,r.rating_reached_at ASC,r.user_id ASC) AS position,
      r.user_id AS "userId",u.nickname,r.rating,r.calibration_completed_matches AS "calibrationCompletedMatches"
      FROM ratings r JOIN users u ON u.id=r.user_id AND u.deleted=false
      WHERE r.deleted=false AND r.discipline_code=:code AND r.season_id=:season)
      SELECT * FROM ranked WHERE position<=50 OR "userId"=:user ORDER BY position
      """,nativeQuery=true)
    List<LeaderboardProjection> leaderboard(@Param("code")String code,@Param("season")String season,@Param("user")UUID user);
    @Modifying
    @Query(value = """
        INSERT INTO ratings (id,created_at,updated_at,deleted,user_id,discipline_code,rating,season_id,calibration_completed_matches,season_peak_rating,all_time_peak_rating,rating_reached_at)
        VALUES (gen_random_uuid(),timezone('UTC',now()),timezone('UTC',now()),false,:userId,:code,1000,:seasonId,0,1000,1000,:reachedAt)
        ON CONFLICT (user_id,discipline_code) WHERE deleted=false DO NOTHING
        """, nativeQuery = true)
    int initializeMissing(@Param("userId") UUID userId, @Param("code") String code,@Param("seasonId") String seasonId,@Param("reachedAt") java.time.Instant reachedAt);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select r from Rating r where r.userId=:userId order by r.disciplineCode")
    List<Rating> lockByUserId(@Param("userId") UUID userId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select r from Rating r where r.userId in :ids and r.disciplineCode = :disciplineCode order by r.userId")
    List<Rating> lockForSettlement(@Param("ids") Collection<UUID> ids, @Param("disciplineCode") String disciplineCode);
}
