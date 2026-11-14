package com.skillbattles.backend.repository;
import com.skillbattles.backend.entity.QuestionReport;import java.util.*;import org.springframework.data.jpa.repository.*;import org.springframework.data.repository.query.Param;
public interface ReportRepository extends JpaRepository<QuestionReport,UUID> {
 Optional<QuestionReport> findByUserIdAndBattleIdAndRoundId(UUID user,UUID battle,UUID round);
 @Modifying @Query(value="""
 INSERT INTO question_reports(id,created_at,updated_at,deleted,user_id,battle_id,round_id,reason,comment)
 VALUES(gen_random_uuid(),timezone('UTC',now()),timezone('UTC',now()),false,:user,:battle,:round,:reason,:comment)
 ON CONFLICT(user_id,battle_id,round_id) WHERE deleted=false DO NOTHING
 """,nativeQuery=true)
 int insert(@Param("user")UUID user,@Param("battle")UUID battle,@Param("round")UUID round,@Param("reason")String reason,@Param("comment")String comment);
}
