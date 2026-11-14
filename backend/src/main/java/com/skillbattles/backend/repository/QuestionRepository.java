package com.skillbattles.backend.repository;

import com.skillbattles.backend.entity.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.time.LocalDateTime;
import java.util.*;

public interface QuestionRepository extends JpaRepository<Question, UUID> {
    List<Question> findAllByExternalKeyIn(Collection<String> externalKeys);
    long countBySubjectAndDifficultyAndActiveTrue(Subject subject, Difficulty difficulty);

    // A local import can run in another JVM. Serialize revision decisions in PostgreSQL, not in memory.
    @Query(value = "SELECT 1 FROM (SELECT pg_advisory_xact_lock(710512002)) import_lock", nativeQuery = true)
    int lockImport();

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("update Question q set q.active = false, q.updatedAt = :now where q.externalKey in :keys and q.active = true and q.deleted = false")
    int deactivate(@Param("keys") Collection<String> keys, @Param("now") LocalDateTime now);
}
