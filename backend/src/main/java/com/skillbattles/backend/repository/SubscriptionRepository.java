package com.skillbattles.backend.repository;
import com.skillbattles.backend.entity.SubscriptionAccount;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import jakarta.persistence.LockModeType;
import java.util.*;

public interface SubscriptionRepository extends JpaRepository<SubscriptionAccount,UUID> {
    @Modifying @Query(value="INSERT INTO subscription_accounts(id,created_at,updated_at,user_id,pro_active) VALUES(gen_random_uuid(),timezone('UTC',now()),timezone('UTC',now()),:userId,true) ON CONFLICT (user_id) WHERE deleted=false DO NOTHING",nativeQuery=true)
    int initialize(@Param("userId") UUID userId);
    Optional<SubscriptionAccount> findByUserId(UUID userId);
    @Lock(LockModeType.PESSIMISTIC_WRITE) @Query("select s from SubscriptionAccount s where s.userId=:id")
    Optional<SubscriptionAccount> lock(@Param("id") UUID id);
    List<SubscriptionAccount> findAllByUserIdIn(Collection<UUID> ids);
}
