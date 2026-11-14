package com.skillbattles.backend.repository;
import com.skillbattles.backend.entity.QualifyingDay;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.time.LocalDate;
import java.util.*;
public interface StreakRepository extends JpaRepository<QualifyingDay,UUID> {
    @Modifying @Query(value="INSERT INTO qualifying_days(id,created_at,updated_at,user_id,activity_date) VALUES(gen_random_uuid(),timezone('UTC',now()),timezone('UTC',now()),:userId,:date) ON CONFLICT (user_id,activity_date) WHERE deleted=false DO NOTHING",nativeQuery=true)
    int qualify(@Param("userId") UUID userId,@Param("date") LocalDate date);
    @Query("select d.activityDate from QualifyingDay d where d.userId=:userId order by d.activityDate")
    List<LocalDate> dates(@Param("userId") UUID userId);
}
