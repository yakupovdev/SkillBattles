package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.RatingDto;
import java.util.*;

public interface RatingService {
    void initialize(UUID userId);
    List<RatingDto> getByUserId(UUID userId);
}
