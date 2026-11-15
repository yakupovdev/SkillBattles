package com.skillbattles.backend.repository;
import com.skillbattles.backend.entity.*;
import jakarta.persistence.LockModeType;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.*;

public interface FriendRelationRepository extends JpaRepository<FriendRelation,UUID> {
    @Lock(LockModeType.PESSIMISTIC_WRITE) @Query("select r from FriendRelation r where r.id=:id")
    Optional<FriendRelation> lock(@Param("id") UUID id);
    List<FriendRelation> findByUserLowIdAndUserHighIdOrderByCreatedAtDescIdAsc(UUID low,UUID high);
    @Query("select r from FriendRelation r, User a, User b where a.id=r.userLowId and b.id=r.userHighId and r.status=:status and (r.userLowId=:user or r.userHighId=:user)")
    Page<FriendRelation> friends(@Param("user") UUID user,@Param("status") FriendStatus status,Pageable page);
    @Query("select r from FriendRelation r, User a, User b where a.id=r.userLowId and b.id=r.userHighId and r.status=:status and ((:incoming=true and r.recipientId=:user) or (:incoming=false and r.requesterId=:user))")
    Page<FriendRelation> requests(@Param("user") UUID user,@Param("incoming") boolean incoming,@Param("status") FriendStatus status,Pageable page);
    @Query("select r from FriendRelation r, User a, User b where a.id=r.userLowId and b.id=r.userHighId and r.status=:status and r.userLowId in :ids and r.userHighId in :ids")
    List<FriendRelation> accepted(@Param("ids") Collection<UUID> ids,@Param("status") FriendStatus status);
}
