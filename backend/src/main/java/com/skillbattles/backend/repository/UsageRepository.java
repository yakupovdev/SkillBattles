package com.skillbattles.backend.repository;
import com.skillbattles.backend.entity.RankedUsage;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.time.LocalDate;
import java.util.*;
public interface UsageRepository extends JpaRepository<RankedUsage,UUID> {
    long countByUserIdAndUsageDateAndRefundedFalse(UUID userId,LocalDate date);
    List<RankedUsage> findByBattleId(UUID battleId);
    @Query("select u.userId from RankedUsage u where u.battleId=:battleId")
    List<UUID> users(@Param("battleId") UUID battleId);
    @Modifying(flushAutomatically=true)
    @Query(value="UPDATE ranked_usage SET refunded=true,updated_at=timezone('UTC',now()) WHERE battle_id=:battleId AND refunded=false AND deleted=false",nativeQuery=true)
    int refund(@Param("battleId") UUID battleId);
    @Query(value="SELECT 1 FROM (SELECT pg_advisory_xact_lock(710512003,hashtext(CAST(:userId AS text)))) quota_lock",nativeQuery=true)
    int lockUser(@Param("userId") UUID userId);
}
