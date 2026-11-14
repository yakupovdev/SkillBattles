package com.skillbattles.backend.repository;
import com.skillbattles.backend.entity.SubscriptionAccount;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import jakarta.persistence.LockModeType;
import java.util.*;
public interface SubscriptionRepository extends JpaRepository<SubscriptionAccount,UUID> {
    @Modifying @Query(value="INSERT INTO subscription_accounts(id,created_at,updated_at,user_id) VALUES(gen_random_uuid(),timezone('UTC',now()),timezone('UTC',now()),:userId) ON CONFLICT (user_id) WHERE deleted=false DO NOTHING",nativeQuery=true)
    int initialize(@Param("userId") UUID userId);
    Optional<SubscriptionAccount> findByUserId(UUID userId);
    @Lock(LockModeType.PESSIMISTIC_WRITE) @Query("select s from SubscriptionAccount s where s.userId=:id")
    Optional<SubscriptionAccount> lock(@Param("id") UUID id);
    Optional<SubscriptionAccount> findByCustomerId(String customerId);
    List<SubscriptionAccount> findAllByUserIdIn(Collection<UUID> ids);
    @Query("select s.userId from SubscriptionAccount s where s.proActive=true and s.currentPeriodEnd<=:now")
    List<UUID> expiring(@Param("now") java.time.Instant now);
    @Query(value="SELECT EXISTS(SELECT 1 FROM stripe_event_receipts WHERE event_id=:eventId)",nativeQuery=true)
    boolean hasEvent(@Param("eventId") String eventId);
}
