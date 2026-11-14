package com.skillbattles.backend.repository;

import com.skillbattles.backend.entity.Rating;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;

public interface RatingRepository extends JpaRepository<Rating, UUID> {
    List<Rating> findAllByUserId(UUID userId);
}
