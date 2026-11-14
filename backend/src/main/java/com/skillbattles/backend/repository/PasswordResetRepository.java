package com.skillbattles.backend.repository;
import com.skillbattles.backend.entity.PasswordResetToken;
import java.util.*;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
public interface PasswordResetRepository extends JpaRepository<PasswordResetToken,UUID> {
 Optional<PasswordResetToken> findByTokenHash(String hash);
 @Modifying(flushAutomatically=true,clearAutomatically=true)
 @Query("update PasswordResetToken t set t.consumedAt=:now where t.tokenHash=:hash and t.userId=:owner and t.consumedAt is null and t.expiresAt>:now and t.deleted=false")
 int consume(@Param("hash")String hash,@Param("owner")UUID owner,@Param("now")java.time.Instant now);
}
