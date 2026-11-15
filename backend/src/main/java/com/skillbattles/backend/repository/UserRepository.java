package com.skillbattles.backend.repository;

import com.skillbattles.backend.entity.User;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.*;

public interface UserRepository extends JpaRepository<User, UUID> {
    Optional<User> findByFriendCode(String friendCode);
    @Query("select u.id from User u order by u.id")
    java.util.List<UUID> activeIds();
    Optional<User> findByEmailNormalized(String email);
    boolean existsByEmailNormalized(String email);
    boolean existsByNicknameNormalized(String nickname);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select u from User u where u.emailNormalized = :email")
    Optional<User> lockByEmail(@Param("email") String email);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select u from User u where u.id = :id")
    Optional<User> lockById(@Param("id") UUID id);
}
