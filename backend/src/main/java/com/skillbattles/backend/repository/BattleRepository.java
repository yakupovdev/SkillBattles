package com.skillbattles.backend.repository;

import com.skillbattles.backend.entity.Battle;
import com.skillbattles.backend.entity.BattleMode;
import org.springframework.data.domain.*;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.*;

public interface BattleRepository extends JpaRepository<Battle, UUID> {
    @Query("select b from Battle b where (b.firstUserId=:userId or b.secondUserId=:userId) and b.phase=com.skillbattles.backend.entity.BattlePhase.FINISHED order by b.finishedAt,b.id")
    List<Battle> finishedHistory(@Param("userId") UUID userId);
    @Query("select b.id from Battle b where (b.firstUserId=:userId or b.secondUserId=:userId) and b.phase in (com.skillbattles.backend.entity.BattlePhase.FINISHED,com.skillbattles.backend.entity.BattlePhase.CANCELLED) order by b.finishedAt desc,b.id desc")
    List<UUID> recentTerminal(@Param("userId") UUID userId,Pageable pageable);

    String HISTORY_FROM = """
         from Battle b where (b.firstUserId = :userId or b.secondUserId = :userId)
           and b.phase in (com.skillbattles.backend.entity.BattlePhase.FINISHED, com.skillbattles.backend.entity.BattlePhase.CANCELLED)
           and (:disciplineCode is null or b.disciplineCode = :disciplineCode) and (:mode is null or b.mode = :mode)
        """;

    @Query(value = "select b.id as battleId, b.disciplineCode as disciplineCode, b.mode as mode, b.phase as phase, b.createdAt as createdAt, b.result as result" + HISTORY_FROM,
           countQuery = "select count(b)" + HISTORY_FROM)
    Page<BattleHistoryProjection> history(@Param("userId") UUID userId, @Param("disciplineCode") String disciplineCode,
                                        @Param("mode") BattleMode mode, Pageable pageable);

    @Query(value="select b.id as battleId,b.disciplineCode as disciplineCode,b.mode as mode,b.phase as phase,b.createdAt as createdAt,b.result as result"+HISTORY_FROM+" and b.id in :ids",
           countQuery="select count(b)"+HISTORY_FROM+" and b.id in :ids")
    Page<BattleHistoryProjection> limitedHistory(@Param("userId") UUID userId,@Param("disciplineCode") String code,@Param("mode") BattleMode mode,@Param("ids") Collection<UUID> ids,Pageable pageable);

    @Query("select count(b)" + HISTORY_FROM)
    long countHistory(@Param("userId") UUID userId, @Param("disciplineCode") String disciplineCode, @Param("mode") BattleMode mode);

    @Query("select b from Battle b where b.id = :id and (b.firstUserId = :userId or b.secondUserId = :userId)")
    Optional<Battle> findForParticipant(@Param("id") UUID id, @Param("userId") UUID userId);

    @Query(value = """
        WITH recent AS (
            SELECT b.id, b.state
            FROM battles b
            WHERE b.deleted = false AND b.discipline_code = :disciplineCode
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
    List<QuestionSeenProjection> recentQuestionShows(@Param("userId") UUID userId, @Param("disciplineCode") String disciplineCode,
                                                    @Param("battleLimit") int battleLimit);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select b from Battle b where b.id = :id")
    Optional<Battle> lockById(@Param("id") UUID id);

    @Query("select b.id from Battle b where b.phase not in (com.skillbattles.backend.entity.BattlePhase.FINISHED, com.skillbattles.backend.entity.BattlePhase.CANCELLED) order by b.id")
    List<UUID> activeIds();

    @Query("select b.id from Battle b where (b.firstUserId = :userId or b.secondUserId = :userId) and b.phase not in (com.skillbattles.backend.entity.BattlePhase.FINISHED, com.skillbattles.backend.entity.BattlePhase.CANCELLED)")
    List<UUID> activeIdsForUser(@Param("userId") UUID userId);

    @Query("select count(b) > 0 from Battle b where (b.firstUserId = :userId or b.secondUserId = :userId) and b.phase not in (com.skillbattles.backend.entity.BattlePhase.FINISHED, com.skillbattles.backend.entity.BattlePhase.CANCELLED)")
    boolean hasActiveBattle(@Param("userId") UUID userId);
    @Query("select (count(b)>0) from Battle b where (b.firstUserId=:userId or b.secondUserId=:userId) and b.disciplineCode=:code and b.mode=com.skillbattles.backend.entity.BattleMode.RANKED and b.phase not in (com.skillbattles.backend.entity.BattlePhase.FINISHED,com.skillbattles.backend.entity.BattlePhase.CANCELLED)")
    boolean hasActiveRankedBattle(@Param("userId") UUID userId,@Param("code") String code);

    @Query("""
        select b.disciplineCode as disciplineCode, b.mode as mode,
          sum(case when b.winnerUserId = :userId then 1 else 0 end) as wins,
          sum(case when b.winnerUserId is not null and b.winnerUserId <> :userId then 1 else 0 end) as losses,
          sum(case when b.winnerUserId is null then 1 else 0 end) as draws, count(b) as played
        from Battle b where b.phase = com.skillbattles.backend.entity.BattlePhase.FINISHED
          and (b.firstUserId = :userId or b.secondUserId = :userId)
        group by b.disciplineCode, b.mode
        """)
    List<BattleStatisticsProjection> statistics(@Param("userId") UUID userId);
}
