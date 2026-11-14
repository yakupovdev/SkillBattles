package com.skillbattles.backend.repository;

import com.skillbattles.backend.entity.Battle;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.*;

public interface BattleRepository extends JpaRepository<Battle, UUID> {
    @Query(value = """
        WITH recent AS (
            SELECT b.id, b.state
            FROM battles b
            WHERE b.deleted = false AND b.subject = :subject
              AND (b.first_user_id = :userId OR b.second_user_id = :userId)
              AND b.state -> 'rounds' -> 0 ->> 'startedAt' IS NOT NULL
            ORDER BY CASE jsonb_typeof(b.state -> 'rounds' -> 0 -> 'startedAt')
                WHEN 'number' THEN to_timestamp(CAST(b.state -> 'rounds' -> 0 ->> 'startedAt' AS double precision))
                ELSE CAST(b.state -> 'rounds' -> 0 ->> 'startedAt' AS timestamp with time zone)
                END DESC, b.id DESC
            LIMIT :battleLimit
        )
        SELECT r.value -> 'question' ->> 'id' AS "questionId", r.value ->> 'startedAt' AS "shownAt"
        FROM recent b CROSS JOIN LATERAL jsonb_array_elements(b.state -> 'rounds') r(value)
        WHERE r.value ->> 'startedAt' IS NOT NULL
        """, nativeQuery = true)
    List<QuestionSeenProjection> recentQuestionShows(@Param("userId") UUID userId, @Param("subject") String subject,
                                                    @Param("battleLimit") int battleLimit);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select b from Battle b where b.id = :id")
    Optional<Battle> lockById(@Param("id") UUID id);

    @Query("select b.id from Battle b where b.phase not in (com.skillbattles.backend.entity.BattlePhase.FINISHED, com.skillbattles.backend.entity.BattlePhase.CANCELLED) order by b.id")
    List<UUID> activeIds();

    @Query("select count(b) > 0 from Battle b where (b.firstUserId = :userId or b.secondUserId = :userId) and b.phase not in (com.skillbattles.backend.entity.BattlePhase.FINISHED, com.skillbattles.backend.entity.BattlePhase.CANCELLED)")
    boolean hasActiveBattle(@Param("userId") UUID userId);

    @Query("""
        select b.subject as subject, b.mode as mode,
          sum(case when b.winnerUserId = :userId then 1 else 0 end) as wins,
          sum(case when b.winnerUserId is not null and b.winnerUserId <> :userId then 1 else 0 end) as losses,
          sum(case when b.winnerUserId is null then 1 else 0 end) as draws, count(b) as played
        from Battle b where b.phase = com.skillbattles.backend.entity.BattlePhase.FINISHED
          and (b.firstUserId = :userId or b.secondUserId = :userId)
        group by b.subject, b.mode
        """)
    List<BattleStatisticsProjection> statistics(@Param("userId") UUID userId);
}
