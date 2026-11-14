package com.skillbattles.backend.repository;

import com.skillbattles.backend.entity.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.time.LocalDateTime;
import java.util.*;

public interface QuestionRepository extends JpaRepository<Question, UUID> {
    List<Question> findAllByExternalKeyIn(Collection<String> externalKeys);
    long countByDisciplineCodeAndDifficultyAndActiveTrue(String disciplineCode, Difficulty difficulty);

    @Query(value = "select * from questions where discipline_code = :disciplineCode and difficulty = :difficulty and active = true and deleted = false order by random() limit :count", nativeQuery = true)
    List<Question> selectForBattle(@Param("disciplineCode") String disciplineCode, @Param("count") int count, @Param("difficulty") String difficulty);

    @Query(value = "select * from questions where discipline_code = :disciplineCode and difficulty = :difficulty and active = true and deleted = false and external_key not in :seenKeys order by random() limit :count", nativeQuery = true)
    List<Question> selectUnseenForBattle(@Param("disciplineCode") String disciplineCode, @Param("count") int count,
                                        @Param("seenKeys") Collection<String> seenKeys, @Param("difficulty") String difficulty);

    @Query(value = "select * from questions where discipline_code = :disciplineCode and difficulty = :difficulty and active = true and deleted = false and external_key in :seenKeys order by random()", nativeQuery = true)
    List<Question> selectSeenForBattle(@Param("disciplineCode") String disciplineCode, @Param("seenKeys") Collection<String> seenKeys, @Param("difficulty") String difficulty);

    // Historical identities must include inactive and soft-deleted revisions. No foreign aggregate is queried here.
    @Query(value = "select id, external_key AS \"externalKey\" from questions where id in :ids", nativeQuery = true)
    List<QuestionIdentityProjection> historicalIdentities(@Param("ids") Collection<UUID> ids);

    // A local import can run in another JVM. Serialize revision decisions in PostgreSQL, not in memory.
    @Query(value = "SELECT 1 FROM (SELECT pg_advisory_xact_lock(710512002)) import_lock", nativeQuery = true)
    int lockImport();

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("update Question q set q.active = false, q.updatedAt = :now where q.externalKey in :keys and q.active = true and q.deleted = false")
    int deactivate(@Param("keys") Collection<String> keys, @Param("now") LocalDateTime now);
}
