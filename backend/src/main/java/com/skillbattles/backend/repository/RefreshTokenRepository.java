package com.skillbattles.backend.repository;

import com.skillbattles.backend.entity.RefreshToken;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.time.*;
import java.util.UUID;

public interface RefreshTokenRepository extends JpaRepository<RefreshToken, UUID> {
    @Modifying(flushAutomatically = true)
    @Query("""
        update RefreshToken t set t.revokedAt = :now, t.updatedAt = :audit
        where t.tokenHash = :hash and t.userId = :userId and t.revokedAt is null
          and t.expiresAt > :now and t.deleted = false
        """)
    int consume(@Param("hash") String hash, @Param("userId") UUID userId,
                @Param("now") Instant now, @Param("audit") LocalDateTime audit);

    @Modifying(flushAutomatically = true)
    @Query("""
        update RefreshToken t set t.revokedAt = :now, t.updatedAt = :audit
        where t.userId = :userId and t.revokedAt is null and t.deleted = false
        """)
    int revokeAll(@Param("userId") UUID userId, @Param("now") Instant now, @Param("audit") LocalDateTime audit);
}
