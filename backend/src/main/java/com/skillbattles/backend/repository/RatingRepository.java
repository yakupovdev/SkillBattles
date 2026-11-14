package com.skillbattles.backend.repository;

import com.skillbattles.backend.entity.Rating;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import jakarta.persistence.LockModeType;
import com.skillbattles.backend.entity.Subject;
import java.util.*;

public interface RatingRepository extends JpaRepository<Rating, UUID> {
    List<Rating> findAllByUserId(UUID userId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select r from Rating r where r.userId in :ids and r.subject = :subject order by r.userId")
    List<Rating> lockForSettlement(@Param("ids") Collection<UUID> ids, @Param("subject") Subject subject);
}
