package com.skillbattles.backend.repository;

import com.skillbattles.backend.entity.RankTierEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;

public interface RankRepository extends JpaRepository<RankTierEntity, UUID> {
    List<RankTierEntity> findAllByOrderByFloorRatingAsc();
}
