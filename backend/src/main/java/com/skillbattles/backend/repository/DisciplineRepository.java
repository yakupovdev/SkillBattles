package com.skillbattles.backend.repository;

import com.skillbattles.backend.entity.Discipline;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.*;

public interface DisciplineRepository extends JpaRepository<Discipline, UUID> {
    List<Discipline> findByActiveTrueOrderByDisplayOrderAscCodeAsc();
    Optional<Discipline> findByCode(String code);
    @Lock(LockModeType.PESSIMISTIC_WRITE) @Query("select d from Discipline d where d.code = :code")
    Optional<Discipline> lockByCode(@Param("code") String code);
}
