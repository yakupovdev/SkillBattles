package com.skillbattles.backend.repository;
import com.skillbattles.backend.entity.SeasonArchive;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.domain.*;
import org.springframework.data.repository.query.Param;
import java.util.*;
public interface SeasonRepository extends JpaRepository<SeasonArchive,UUID> {
    Optional<SeasonArchive> findByUserIdAndDisciplineCodeAndSeasonId(UUID userId,String disciplineCode,String seasonId);
    @Query(value="select a from SeasonArchive a where a.userId=:userId and (:code is null or a.disciplineCode=:code) order by a.seasonStartsAt desc, a.disciplineCode asc",
           countQuery="select count(a) from SeasonArchive a where a.userId=:userId and (:code is null or a.disciplineCode=:code)")
    Page<SeasonArchive> history(@Param("userId") UUID userId,@Param("code") String code,Pageable pageable);
}
